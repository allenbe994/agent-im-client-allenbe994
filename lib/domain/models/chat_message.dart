import 'package:equatable/equatable.dart';

import 'tool_call.dart';

enum ChatRole { user, agent, system }

enum ChatMessageType {
  userText,
  agentMarkdown,
  toolCard,
  thinking,
}

enum ChatMessageStatus {
  sending,
  sent,
  failed,
  streaming,
  done,
}

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.type,
    required this.createdAtMs,
    required this.status,
    this.text,
    this.toolCall,
    this.isExpanded,
  });

  final String id;
  final String sessionId;
  final ChatRole role;
  final ChatMessageType type;
  final int createdAtMs;
  final ChatMessageStatus status;

  final String? text;
  final ToolCall? toolCall;
  final bool? isExpanded; // 仅 tool 卡片用

  bool get isThinking => type == ChatMessageType.thinking;
  bool get isAgentMarkdown => type == ChatMessageType.agentMarkdown;
  bool get isToolCard => type == ChatMessageType.toolCard;

  ChatMessage copyWith({
    ChatMessageStatus? status,
    String? text,
    ToolCall? toolCall,
    bool? isExpanded,
  }) {
    return ChatMessage(
      id: id,
      sessionId: sessionId,
      role: role,
      type: type,
      createdAtMs: createdAtMs,
      status: status ?? this.status,
      text: text ?? this.text,
      toolCall: toolCall ?? this.toolCall,
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sessionId,
        role,
        type,
        createdAtMs,
        status,
        text,
        toolCall,
        isExpanded,
      ];
}

