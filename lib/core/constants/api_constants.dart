import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final value = dotenv.env['API_BASE_URL'];
    if (value != null && value.isNotEmpty) return value;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://127.0.0.1:5000/api';
  }

  static String get socketUrl {
    final value = dotenv.env['SOCKET_URL'];
    if (value != null && value.isNotEmpty) return value;
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }
}
