import 'dart:async';
import 'dart:math';

import '../../core/utils/uuid.dart';
import '../../domain/models/chat_event.dart';
import 'ws_client.dart';

class MockWsClient extends MemoryWsClientBase {
  MockWsClient({
    this.minDeltaInterval = const Duration(milliseconds: 15),
    this.chunkSize = 2,
  });
// 定时器实现打字机
  final Duration minDeltaInterval;
  final int chunkSize;

  int _eventId = 0;  //事件自增
  String? _sessionId;
  Timer? _timer;
  WsConnectionStatus _status = WsConnectionStatus.disconnected;

  int _nextEventId() => ++_eventId;

  @override
  Future<void> connect({required String sessionId, required int lastEventId}) async {
    _sessionId = sessionId;
    _eventId = max(_eventId, lastEventId);
    _status = WsConnectionStatus.connecting;
    emitConn(WsConnectionStatus.connecting);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (isClosed) return;
    _status = WsConnectionStatus.connected;
    emitConn(WsConnectionStatus.connected);
  }

  //这块是 angentloop核心了 思路
  @override
  Future<void> sendUserMessage({required String sessionId, required String text}) async {
    if (_status != WsConnectionStatus.connected) {
      throw StateError('未连接，无法发送');
    }
    if (_sessionId != sessionId) _sessionId = sessionId;
    _timer?.cancel();

    //是否调用工具
    final plan = _planFor(text);
    final agentMessageId = UuidUtil.v4();

    // 一条回复可包含多轮：thinking → tool_call → tool_result → text_delta → thinking → ...
    emitEvent(ChatEvent(sessionId: sessionId, eventId: _nextEventId(), type: ChatEventType.thinking));
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final out = StringBuffer();
    out.writeln('下面是一段“Agent 多轮工具调用”的 mock 演示：');
    out.writeln();
    out.writeln('你输入：`$text`');
    out.writeln();

    for (var i = 0; i < plan.length; i++) {
      if (isClosed) return;
      final step = plan[i];

      // thinking（每一轮工具前都来一次，让 UI 看到循环）
      emitEvent(ChatEvent(sessionId: sessionId, eventId: _nextEventId(), type: ChatEventType.thinking));
      await Future<void>.delayed(const Duration(milliseconds: 160));

      final callId = UuidUtil.v4();
      emitEvent(
        ChatEvent(
          sessionId: sessionId,
          eventId: _nextEventId(),
          type: ChatEventType.toolCall,
          callId: callId,
          toolName: step.toolName,
          argsJson: step.argsJson,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 220));
      emitEvent(
        ChatEvent(
          sessionId: sessionId,
          eventId: _nextEventId(),
          type: ChatEventType.toolResult,
          callId: callId,
          resultJson: step.resultJson,
        ),
      );

      out.writeln('- 第 ${i + 1} 轮工具：`${step.toolName}`');
      out.writeln('  - args: `${step.humanArgs}`');
      out.writeln('  - result: `${step.humanResult}`');
      out.writeln();

      // 每轮工具后都追加一段 text_delta（模拟模型基于工具结果继续生成）
      out.writeln('（模型）已拿到工具结果，继续生成中……');
      out.writeln();
    }

    if (plan.isEmpty) {
      out.writeln('- 本轮未触发工具（输入不像算式/天气查询），直接生成回复。');
      out.writeln();
    }

    out.writeln('最终结论如上!!');

    _startDeltaStream(sessionId: sessionId, agentMessageId: agentMessageId, fullText: out.toString());
  }

  void _startDeltaStream({
    required String sessionId,
    required String agentMessageId,
    required String fullText,
  }) {
    var idx = 0;
    _timer = Timer.periodic(minDeltaInterval, (t) {
      if (isClosed) {
        t.cancel();
        _timer = null;
        return;
      }
      if (idx >= fullText.length) {
        t.cancel();
        _timer = null;
        emitEvent(
          ChatEvent(
            sessionId: sessionId,
            eventId: _nextEventId(),
            type: ChatEventType.done,
            messageId: agentMessageId,
          ),
        );
        return;
      }
      final end = min(idx + chunkSize, fullText.length);
      final delta = fullText.substring(idx, end);
      idx = end;
      emitEvent(
        ChatEvent(
          sessionId: sessionId,
          eventId: _nextEventId(),
          type: ChatEventType.textDelta,
          messageId: agentMessageId,
          delta: delta,
        ),
      );
    });
  }

  List<_ToolStep> _planFor(String raw) {
    final steps = <_ToolStep>[];
    final s = raw.trim();

    // 1) 计算器：能抓到算式就算
    final calc = _mockCalculator(s);
    if (calc.ok) {
      steps.add(
        _ToolStep(
          toolName: 'calculator',
          argsJson: '{"expression":${_jsonString(calc.expression)}}',
          resultJson: calc.resultJson,
          humanArgs: calc.expression,
          humanResult: calc.humanReadable,
        ),
      );
    }

    // 2) 天气：命中关键词就查
    final weather = _mockWeather(s);
    if (weather.ok) {
      steps.add(
        _ToolStep(
          toolName: 'weather',
          argsJson: '{"city":${_jsonString(weather.city)}}',
          resultJson: weather.resultJson,
          humanArgs: weather.city,
          humanResult: weather.humanReadable,
        ),
      );
    }

    // 3) 如果同时命中，顺序：先 weather 再 calculator
    if (steps.length == 2 && steps[0].toolName == 'calculator' && steps[1].toolName == 'weather') {
      return [steps[1], steps[0]];
    }
    return steps;
  }

  ({bool ok, String expression, String resultJson, String humanReadable}) _mockCalculator(String raw) {
    // 尽量从输入里抓一个最常见的表达式
    final s = raw.replaceAll('×', '*').replaceAll('÷', '/');
    final m = RegExp(r'(-?\d+(?:\.\d+)?)\s*([\+\-\*\/])\s*(-?\d+(?:\.\d+)?)').firstMatch(s);
    if (m == null) {
      return (
        ok: false,
        expression: '',
        resultJson: '{"ok":false,"error":${_jsonString('未识别到算式')}}',
        humanReadable: '未识别到算式',
      );
    }
    final a = double.tryParse(m.group(1)!);
    final op = m.group(2)!;
    final b = double.tryParse(m.group(3)!);
    if (a == null || b == null) {
      return (
        ok: false,
        expression: m.group(0) ?? '',
        resultJson: '{"ok":false,"error":${_jsonString('数字解析失败')}}',
        humanReadable: '数字解析失败',
      );
    }
    double? v;
    switch (op) {
      case '+':
        v = a + b;
        break;
      case '-':
        v = a - b;
        break;
      case '*':
        v = a * b;
        break;
      case '/':
        if (b == 0) {
          return (
            ok: false,
            expression: m.group(0) ?? '',
            resultJson: '{"ok":false,"error":${_jsonString('除数不能为 0')}}',
            humanReadable: '除数不能为 0',
          );
        }
        v = a / b;
        break;
    }
    final pretty = _prettyNumber(v ?? double.nan);
    return (
      ok: true,
      expression: m.group(0) ?? '',
      resultJson: '{"ok":true,"value":${_jsonString(pretty)}}',
      humanReadable: pretty,
    );
  }

  ({bool ok, String city, String resultJson, String humanReadable}) _mockWeather(String raw) {
    final hit = RegExp(r'(天气|温度|下雨|晴|多云|气温)').hasMatch(raw);
    if (!hit) {
      return (ok: false, city: '', resultJson: '{"ok":false}', humanReadable: '');
    }
    final city = _extractCity(raw) ?? '北京';
    // 纯 mock：为了演示工具链路稳定可复现
    final temp = 18 + (city.codeUnitAt(0) % 10);
    final descs = ['晴', '多云', '小雨', '阴'];
    final desc = descs[city.codeUnitAt(city.length - 1) % descs.length];
    final human = '$city：$desc，$temp℃';
    return (
      ok: true,
      city: city,
      resultJson: '{"ok":true,"city":${_jsonString(city)},"desc":${_jsonString(desc)},"temp":$temp}',
      humanReadable: human,
    );
  }

  String? _extractCity(String raw) {
    // 极简抽取：形如“北京天气”“上海的温度”
    final m = RegExp(r'([\u4e00-\u9fa5]{2,6})(?:的)?(?:天气|温度|气温)').firstMatch(raw);
    return m?.group(1);
  }

  static String _prettyNumber(double v) {
    if (v.isNaN) return 'NaN';
    if (v.isInfinite) return v.isNegative ? '-Infinity' : 'Infinity';
    final i = v.toInt();
    if ((v - i).abs() < 1e-9) return i.toString();
    return v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }

  static String _jsonString(String s) {
    // 最小 JSON string escape
    final escaped = s
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
    return '"$escaped"';
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _timer = null;
    _status = WsConnectionStatus.disconnected;
    emitConn(WsConnectionStatus.disconnected);
    await super.close();
  }
}

class _ToolStep {
  const _ToolStep({
    required this.toolName,
    required this.argsJson,
    required this.resultJson,
    required this.humanArgs,
    required this.humanResult,
  });

  final String toolName;
  final String argsJson;
  final String resultJson;
  final String humanArgs;
  final String humanResult;
}
