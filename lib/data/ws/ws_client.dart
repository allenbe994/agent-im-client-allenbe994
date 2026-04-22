import 'dart:async';

import '../../domain/models/chat_event.dart';

// 四种状态的枚举
enum WsConnectionStatus { disconnected, connecting, connected, reconnecting  }

  //ws接口
abstract class WsClient {
  Stream<ChatEvent> get events;//接受事件
  Stream<WsConnectionStatus> get connectionStates;//监听连接

  Future<void> connect({required String sessionId, required int lastEventId});
  // 给客户端发消息的父类
  Future<void> sendUserMessage({required String sessionId, required String text});
  Future<void> close();
}

//基类(内存模拟）））
class MemoryWsClientBase implements WsClient {
  final _events = StreamController<ChatEvent>.broadcast();// 广播流控制器
  final _conn = StreamController<WsConnectionStatus>.broadcast();
  bool _closed = false;

  @override
  Stream<ChatEvent> get events => _events.stream;

  @override
  Stream<WsConnectionStatus> get connectionStates => _conn.stream;

  bool get isClosed => _closed;

  void emitEvent(ChatEvent e) {
    if (_closed || _events.isClosed) return;
    _events.add(e);
  }

  void emitConn(WsConnectionStatus s) {
    if (_closed || _conn.isClosed) return;
    _conn.add(s);
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _events.close();
    await _conn.close();
  }

  @override
  Future<void> connect({required String sessionId, required int lastEventId}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> sendUserMessage({required String sessionId, required String text}) async {
    throw UnimplementedError();
  }
}

