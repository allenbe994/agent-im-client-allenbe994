import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/models/chat_message.dart';
import '../../cubit/chat_cubit.dart';

class ToolCardMessage extends StatelessWidget {
  const ToolCardMessage({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final call = message.toolCall;
    if (call == null) return const SizedBox.shrink();

    final expanded = message.isExpanded ?? false;
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.55),
          child: InkWell(
            onTap: () => context.read<ChatCubit>().toggleToolExpanded(call.callId),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '工具：${call.toolName}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Icon(expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                  const SizedBox(height: 8),
                  //开关
                  if(expanded)...[
                    Text(
                      'args: ${call.argsJson}',
                      maxLines: expanded ? 99 : 1,
                      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'result: ${call.resultJson ?? '(等待结果…)'}',
                      maxLines: expanded ? 99 : 1,
                      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

