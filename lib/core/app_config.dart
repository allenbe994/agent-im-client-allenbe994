enum RuntimeMode { mock, ws }

class AppConfig {
  /// 先默认 mock，保证随时可演示。
  static const RuntimeMode mode = RuntimeMode.mock;

  /// 将来接真实 WS/Agent Server 时用。
  static const String wsUrl = 'ws://127.0.0.1:8765/ws';
}

