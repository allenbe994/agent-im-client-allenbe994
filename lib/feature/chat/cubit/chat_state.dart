import 'package:equatable/equatable.dart';

import '../../../data/ws/ws_client.dart';
import '../../../domain/models/chat_message.dart';

enum StreamPhase { idle, thinking, toolCalling, responding }

class ChatState extends Equatable {
  const ChatState({
    required this.sessionId,
    required this.messages,
    required this.connection,
    required this.streamPhase,
    required this.lastEventId,
  });

  final String sessionId;
  final List<ChatMessage> messages;
  final WsConnectionStatus connection;
  final StreamPhase streamPhase;
  final int lastEventId;

  ChatState copyWith({
    List<ChatMessage>? messages,
    WsConnectionStatus? connection,
    StreamPhase? streamPhase,
    int? lastEventId,
  }) {
    return ChatState(
      sessionId: sessionId,
      messages: messages ?? this.messages,
      connection: connection ?? this.connection,
      streamPhase: streamPhase ?? this.streamPhase,
      lastEventId: lastEventId ?? this.lastEventId,
    );
  }

  @override
  List<Object?> get props => [sessionId, messages, connection, streamPhase, lastEventId];
}

