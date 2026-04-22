import 'hive_boxes.dart';
import 'hive_mappers.dart';
import '../../feature/session/cubit/session_state.dart';

class SessionStore {
  List<Session> loadAll() {
    final box = HiveBoxes.sessionsBox;
    return box.values.map((m) => HiveMappers.sessionFromMap(m)).toList(growable: false);
  }

  Future<void> upsert(Session s) async {
    await HiveBoxes.sessionsBox.put(s.id, HiveMappers.sessionToMap(s));
  }

  Future<void> delete(String id) async {
    await HiveBoxes.sessionsBox.delete(id);
    await HiveBoxes.messagesBox.delete(id); // 顺手清理该会话消息
  }
}

