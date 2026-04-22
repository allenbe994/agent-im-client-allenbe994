import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/log.dart';
import '../../../core/utils/debounce.dart';
import '../../../core/utils/uuid.dart';
import '../../../data/local/chat_store.dart';
import '../../../data/ws/ws_client.dart';
import '../../../domain/models/chat_event.dart';
import '../../../domain/models/chat_message.dart';
import '../../../domain/models/tool_call.dart';
import '../../session/cubit/session_cubit.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit({
    required this.ws,
    required this.sessionCubit,
    required String sessionId,
    required int lastEventId,
    ChatStore? store,
  })  : _store = store ?? ChatStore(),
        super(
          ChatState(
            sessionId: sessionId,
            messages: const [],
            connection: WsConnectionStatus.disconnected,
            streamPhase: StreamPhase.idle,
            lastEventId: lastEventId,
          ),
        );

  final WsClient ws;
  final SessionCubit sessionCubit;
  final ChatStore _store;

  StreamSubscription? _eventSub;
  StreamSubscription? _connSub;

  final _dedup = HashSet<String>();
  static const int _dedupMax = 5000;

  //防止打字机高频刷新 ，无论怎么发都只80 build一次
  final Throttler _uiThrottler = Throttler(const Duration(milliseconds: 80));
  final Debouncer _dbDebouncer = Debouncer(const Duration(milliseconds: 450));
  final Debouncer _persistDebouncer = Debouncer(const Duration(milliseconds: 400));

  final Map<String, StringBuffer> _streamBuffers = {};

  Future<void> init() async {
    // 先加载本地历史
    final history = _store.loadMessages(state.sessionId);
    if (history.isNotEmpty) {
      for (final m in history) {
        if (m.type == ChatMessageType.agentMarkdown && m.text != null) {
          _streamBuffers[m.id] = StringBuffer(m.text!);
        }
      }
      emit(state.copyWith(messages: history));
    }

    await _eventSub?.cancel();
    await _connSub?.cancel();

    _connSub = ws.connectionStates.listen((s) {
      emit(state.copyWith(connection: s));
    });
//接受 ws的事件
    _eventSub = ws.events.listen(
      (e) => onEvent(e),
      onError: (err, st) => Log.d('ws events error', error: err, stackTrace: st),
    );

    await ws.connect(sessionId: state.sessionId, lastEventId: state.lastEventId);
  }

  Future<void> dispose() async {
    await _eventSub?.cancel();
    await _connSub?.cancel();
    _uiThrottler.dispose();
    _dbDebouncer.dispose();
    _persistDebouncer.dispose();
    await ws.close();
  }

  void _schedulePersist(List<ChatMessage> msgs) {
    _persistDebouncer(() async {
      await _store.saveMessages(state.sessionId, msgs);
    });
  }

  Future<void> send(String text) async {
    final t = text.trim();
    if (t.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final userMsg = ChatMessage(
      id: UuidUtil.v4(),
      sessionId: state.sessionId,
      role: ChatRole.user,
      type: ChatMessageType.userText,
      createdAtMs: now,
      status: ChatMessageStatus.sending,
      text: t,
    );

    final next = [...state.messages, userMsg];
    // 乐观展示
    final withThinking = [...next];
    if (withThinking.isEmpty || !withThinking.last.isThinking) {
      withThinking.add(
        ChatMessage(
          id: 'thinking',
          sessionId: state.sessionId,
          role: ChatRole.agent,
          type: ChatMessageType.thinking,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          status: ChatMessageStatus.streaming,
        ),
      );
    }
    emit(state.copyWith(messages: withThinking, streamPhase: StreamPhase.thinking));
    _schedulePersist(withThinking);

    try {
      await ws.sendUserMessage(sessionId: state.sessionId, text: t);
      _markUserSent(userMsg.id);
    } catch (e, st) {
      Log.d('send failed', error: e, stackTrace: st);
      _markUserFailed(userMsg.id);
    }
  }

  void _markUserSent(String messageId) {
    final msgs = [...state.messages];
    final idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    msgs[idx] = msgs[idx].copyWith(status: ChatMessageStatus.sent);
    emit(state.copyWith(messages: msgs));
    _schedulePersist(msgs);
  }

  void _markUserFailed(String messageId) {
    final msgs = [...state.messages];
    final idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    msgs[idx] = msgs[idx].copyWith(status: ChatMessageStatus.failed);
    emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.idle));
    _schedulePersist(msgs);
  }

  Future<void> retry(String messageId) async {
    final m = state.messages.firstWhere((e) => e.id == messageId, orElse: () => throw StateError('message not found'));
    if (m.role != ChatRole.user || m.type != ChatMessageType.userText) return;
    if (m.text == null || m.text!.trim().isEmpty) return;

    final msgs = [...state.messages];
    final idx = msgs.indexWhere((e) => e.id == messageId);
    if (idx < 0) return;
    msgs[idx] = msgs[idx].copyWith(status: ChatMessageStatus.sending);

    // 重试时同样保证有 thinking
    if (msgs.isEmpty || !msgs.last.isThinking) {
      msgs.add(
        ChatMessage(
          id: 'thinking',
          sessionId: state.sessionId,
          role: ChatRole.agent,
          type: ChatMessageType.thinking,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          status: ChatMessageStatus.streaming,
        ),
      );
    }
    emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.thinking));
    _schedulePersist(msgs);

    try {
      await ws.sendUserMessage(sessionId: state.sessionId, text: m.text!.trim());
      _markUserSent(messageId);
    } catch (e, st) {
      Log.d('retry failed', error: e, stackTrace: st);
      _markUserFailed(messageId);
    }
  }

  void onEvent(ChatEvent e) {
    if (e.sessionId != state.sessionId) return;

    final key = '${e.sessionId}:${e.eventId}';
    if (_dedup.contains(key)) return;
    _dedup.add(key);
    if (_dedup.length > _dedupMax) {
      final toRemove = _dedup.take(300).toList(growable: false);
      for (final k in toRemove) {
        _dedup.remove(k);
      }
    }

    final nextLast = max(state.lastEventId, e.eventId);
    if (nextLast != state.lastEventId) {
      sessionCubit.updateLastEventId(state.sessionId, nextLast);
    }

    switch (e.type) {
      case ChatEventType.thinking:
        _applyThinking(nextLast);
        break;
      case ChatEventType.toolCall:
        _applyToolCall(e, nextLast);
        break;
      case ChatEventType.toolResult:
        _applyToolResult(e, nextLast);
        break;
      case ChatEventType.textDelta:
        _applyTextDelta(e, nextLast);
        break;
      case ChatEventType.done:
        _applyDone(nextLast);
        break;
      case ChatEventType.error:
        _applyError(e, nextLast);
        break;
    }
  }

  void _applyThinking(int nextLast) {
    final msgs = [...state.messages];
    if (msgs.isEmpty || !msgs.last.isThinking) {
      msgs.add(
        ChatMessage(
          id: 'thinking',
          sessionId: state.sessionId,
          role: ChatRole.agent,
          type: ChatMessageType.thinking,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          status: ChatMessageStatus.streaming,
        ),
      );
    }
    emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.thinking, lastEventId: nextLast));
    _schedulePersist(msgs);
  }

  void _removeThinkingIfAny(List<ChatMessage> msgs) {
    if (msgs.isNotEmpty && msgs.last.isThinking) {
      msgs.removeLast();
    }
  }

  void _applyToolCall(ChatEvent e, int nextLast) {
    final msgs = [...state.messages];
    _removeThinkingIfAny(msgs);
    msgs.add(
      ChatMessage(
        id: UuidUtil.v4(),
        sessionId: state.sessionId,
        role: ChatRole.agent,
        type: ChatMessageType.toolCard,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        status: ChatMessageStatus.streaming,
        toolCall: ToolCall(
          callId: e.callId ?? '',
          toolName: e.toolName ?? 'tool',
          argsJson: e.argsJson ?? '{}',
        ),
        isExpanded: false,
      ),
    );

    emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.toolCalling, lastEventId: nextLast));
    _schedulePersist(msgs);
  }

  void _applyToolResult(ChatEvent e, int nextLast) {
    final callId = e.callId;
    if (callId == null) return;
    final msgs = [...state.messages];
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      if (m.isToolCard && m.toolCall?.callId == callId) {
        msgs[i] = m.copyWith(toolCall: m.toolCall!.copyWith(resultJson: e.resultJson));
        emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.toolCalling, lastEventId: nextLast));
        _schedulePersist(msgs);
        return;
      }
    }
  }

  void toggleToolExpanded(String callId) {
    final msgs = [...state.messages];
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      if (m.isToolCard && m.toolCall?.callId == callId) {
        msgs[i] = m.copyWith(isExpanded: !(m.isExpanded ?? false));
        emit(state.copyWith(messages: msgs));
        _schedulePersist(msgs);
        return;
      }
    }
  }

  void _applyTextDelta(ChatEvent e, int nextLast) {
    final messageId = e.messageId;
    final delta = e.delta;
    if (messageId == null || delta == null || delta.isEmpty) return;

    final msgs = [...state.messages];
    _removeThinkingIfAny(msgs);

    final buf = _streamBuffers.putIfAbsent(messageId, () => StringBuffer());
    buf.write(delta);
    final fullText = buf.toString();

    var idx = msgs.indexWhere((m) => m.id == messageId);
    if (idx < 0) {
      msgs.add(
        ChatMessage(
          id: messageId,
          sessionId: state.sessionId,
          role: ChatRole.agent,
          type: ChatMessageType.agentMarkdown,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          status: ChatMessageStatus.streaming,
          text: fullText,
        ),
      );
    } else {
      msgs[idx] = msgs[idx].copyWith(text: fullText, status: ChatMessageStatus.streaming);
    }

    // UI 节流：高频 delta 先缓冲，再合并 emit
    _uiThrottler(() {
      emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.responding, lastEventId: nextLast));
    });

    // 本地持久化节流：避免每个 delta 都整表写
    _dbDebouncer(() {
      _schedulePersist(msgs);
    });
  }

  void _applyDone(int nextLast) {
    final msgs = [...state.messages];
    _removeThinkingIfAny(msgs);

    // 把最后一条 streaming 的 agent markdown 标记 done（若存在）
    for (var i = msgs.length - 1; i >= 0; i--) {
      final m = msgs[i];
      if (m.isAgentMarkdown && m.status == ChatMessageStatus.streaming) {
        msgs[i] = m.copyWith(status: ChatMessageStatus.done);
        break;
      }
    }
    _dbDebouncer.flushNow(() {
      _schedulePersist(msgs);
    });
    emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.idle, lastEventId: nextLast));
    _schedulePersist(msgs);
  }

  void _applyError(ChatEvent e, int nextLast) {
    final msgs = [...state.messages];
    _removeThinkingIfAny(msgs);
    msgs.add(
      ChatMessage(
        id: UuidUtil.v4(),
        sessionId: state.sessionId,
        role: ChatRole.system,
        type: ChatMessageType.userText,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        status: ChatMessageStatus.done,
        text: '错误：${e.errorMessage ?? '未知错误'}',
      ),
    );
    emit(state.copyWith(messages: msgs, streamPhase: StreamPhase.idle, lastEventId: nextLast));
    _schedulePersist(msgs);
  }
}

