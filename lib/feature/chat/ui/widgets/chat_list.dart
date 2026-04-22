import 'package:flutter/material.dart';

import '../../../../domain/models/chat_message.dart';
import 'message_bubble.dart';
import 'thinking_indicator.dart';
import 'tool_card_message.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key, required this.messages});

  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, i) {
        final m = messages[i];
        if (m.type == ChatMessageType.thinking) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: ThinkingIndicator(),
          );
        }
        if (m.type == ChatMessageType.toolCard) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ToolCardMessage(message: m),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: MessageBubble(message: m),
        );
      },
    );
  }
}

