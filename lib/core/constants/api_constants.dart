import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl => String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );
  static String get socketUrl => String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: _defaultSocketUrl,
  );

  static String get _defaultApiBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000/api';
    return 'http://127.0.0.1:5000/api';
  }

  static String get _defaultSocketUrl {
    if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
    return 'http://127.0.0.1:5000';
  }
}
