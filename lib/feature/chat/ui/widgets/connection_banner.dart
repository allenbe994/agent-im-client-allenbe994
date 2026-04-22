import 'package:flutter/material.dart';

import '../../../../data/ws/ws_client.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.status});

  final WsConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      WsConnectionStatus.connected => ('已连接', Colors.green),
      WsConnectionStatus.connecting => ('连接中…', Colors.orange),
      WsConnectionStatus.reconnecting => ('重连中…', Colors.orange),
      WsConnectionStatus.disconnected => ('已断开', Colors.red),
    };

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      color: color.withValues(alpha: 0.12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

