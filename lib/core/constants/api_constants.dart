import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    final value = dotenv.env['API_BASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('API_BASE_URL is missing from .env');
    }
    return value;
  }

  static String get socketUrl {
    final value = dotenv.env['SOCKET_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('SOCKET_URL is missing from .env');
    }
    return value;
  }

  static String get frontendUrl {
    final value = dotenv.env['FRONTEND_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('FRONTEND_URL is missing from .env');
    }
    return value;
  }

  static String get publicBaseUrl {
    final value = dotenv.env['PUBLIC_BASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('PUBLIC_BASE_URL is missing from .env');
    }
    return value;
  }
}
