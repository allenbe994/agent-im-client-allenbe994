import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/chat_message.dart';
import '../../cubit/chat_cubit.dart';
import 'agent_markdown_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;
    final bg = isUser ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final align = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final radius = BorderRadius.circular(12);

    Widget child;
    if (message.type == ChatMessageType.agentMarkdown) {
      child = AgentMarkdownMessage(text: message.text ?? '');
    } else {
      child = Text(message.text ?? '');
    }

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              child,
              if (isUser && message.status == ChatMessageStatus.failed)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '发送失败',
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => context.read<ChatCubit>().retry(message.id),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

