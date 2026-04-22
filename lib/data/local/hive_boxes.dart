import 'package:hive/hive.dart';

class HiveBoxes {
  static const String sessions = 'sessions';
  static const String messages = 'messages';

  static Box<Map> get sessionsBox => Hive.box<Map>(sessions);
  static Box<List> get messagesBox => Hive.box<List>(messages);
}

