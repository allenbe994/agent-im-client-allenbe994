import '../../domain/models/chat_message.dart';
import '../../domain/models/tool_call.dart';
import '../../feature/session/cubit/session_state.dart';

class HiveMappers {
  static Map<String, dynamic> sessionToMap(Session s) => {
        'id': s.id,
        'title': s.title,
        'createdAtMs': s.createdAtMs,
        'updatedAtMs': s.updatedAtMs,
        'lastEventId': s.lastEventId,
      };

  static Session sessionFromMap(Map m) => Session(
        id: (m['id'] ?? '') as String,
        title: (m['title'] ?? 'New Chat') as String,
        createdAtMs: (m['createdAtMs'] ?? 0) as int,
        updatedAtMs: (m['updatedAtMs'] ?? 0) as int,
        lastEventId: (m['lastEventId'] ?? 0) as int,
      );

  static Map<String, dynamic> messageToMap(ChatMessage m) => {
        'id': m.id,
        'sessionId': m.sessionId,
        'role': m.role.name,
        'type': m.type.name,
        'createdAtMs': m.createdAtMs,
        'status': m.status.name,
        'text': m.text,
        'isExpanded': m.isExpanded,
        'toolCall': m.toolCall == null
            ? null
            : {
                'callId': m.toolCall!.callId,
                'toolName': m.toolCall!.toolName,
                'argsJson': m.toolCall!.argsJson,
                'resultJson': m.toolCall!.resultJson,
              },
      };

  static ChatMessage messageFromMap(Map m) => ChatMessage(
        id: (m['id'] ?? '') as String,
        sessionId: (m['sessionId'] ?? '') as String,
        role: ChatRole.values.byName((m['role'] ?? 'user') as String),
        type: ChatMessageType.values.byName((m['type'] ?? 'userText') as String),
        createdAtMs: (m['createdAtMs'] ?? 0) as int,
        status: ChatMessageStatus.values.byName((m['status'] ?? 'done') as String),
        text: m['text'] as String?,
        isExpanded: m['isExpanded'] as bool?,
        toolCall: m['toolCall'] == null
            ? null
            : ToolCall(
                callId: ((m['toolCall'] as Map)['callId'] ?? '') as String,
                toolName: ((m['toolCall'] as Map)['toolName'] ?? '') as String,
                argsJson: ((m['toolCall'] as Map)['argsJson'] ?? '{}') as String,
                resultJson: ((m['toolCall'] as Map)['resultJson']) as String?,
              ),
      );
}

