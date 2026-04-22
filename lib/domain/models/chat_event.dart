import 'package:equatable/equatable.dart';

enum ChatEventType {
  thinking,
  toolCall,
  toolResult,
  textDelta,
  done,
  error,
}

class ChatEvent extends Equatable {
  const ChatEvent({
    required this.sessionId,
    required this.eventId,
    required this.type,
    this.messageId,
    this.callId,
    this.toolName,
    this.argsJson,
    this.resultJson,
    this.delta,
    this.errorMessage,
  });

  final String sessionId;
  final int eventId;
  final ChatEventType type;

  final String? messageId; // 用于 text_delta 绑定同一条 agent 消息
  final String? callId;
  final String? toolName;
  final String? argsJson;
  final String? resultJson;
  final String? delta;
  final String? errorMessage;

  @override
  List<Object?> get props => [
        sessionId,
        eventId,
        type,
        messageId,
        callId,
        toolName,
        argsJson,
        resultJson,
        delta,
        errorMessage,
      ];
}

