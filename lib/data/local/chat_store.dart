import '../../domain/models/chat_message.dart';
import 'hive_boxes.dart';
import 'hive_mappers.dart';

class ChatStore {
  List<ChatMessage> loadMessages(String sessionId) {
    final list = HiveBoxes.messagesBox.get(sessionId);
    if (list == null) return const [];
    return list.whereType<Map>().map((m) => HiveMappers.messageFromMap(m)).toList(growable: false);
  }

  Future<void> saveMessages(String sessionId, List<ChatMessage> messages) async {
    // thinking 属于 UI 临时态，不落盘
    final persist = messages.where((m) => m.type != ChatMessageType.thinking).map(HiveMappers.messageToMap).toList(growable: false);
    await HiveBoxes.messagesBox.put(sessionId, persist);
  }
}

