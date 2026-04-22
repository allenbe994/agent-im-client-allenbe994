import 'dart:convert';

class JsonUtil {
  static Map<String, dynamic> asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is String) return jsonDecode(v) as Map<String, dynamic>;
    throw StateError('不是合法的 JSON 对象：$v');
  }

  static String encode(Object? v) => jsonEncode(v);
}

