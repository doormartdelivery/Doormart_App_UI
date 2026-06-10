import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final value = dotenv.env['API_BASE_URL'];
    if (value != null && value.isNotEmpty) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return value.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      }
      return value;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://127.0.0.1:5000/api';
  }

  static String get socketUrl {
    final value = dotenv.env['SOCKET_URL'];
    if (value != null && value.isNotEmpty) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return value.replaceAll('localhost', '10.0.2.2').replaceAll('127.0.0.1', '10.0.2.2');
      }
      return value;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000';
    }
    return 'http://127.0.0.1:5000';
  }
}

