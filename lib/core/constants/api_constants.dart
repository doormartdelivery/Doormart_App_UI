import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String _url(String key, String buildValue) {
    final value = (buildValue.isNotEmpty ? buildValue : dotenv.env[key] ?? '')
        .trim();
    if (value.isEmpty) throw StateError('$key is missing');
    final uri = Uri.tryParse(value);
    if (kReleaseMode &&
        (uri == null || uri.scheme != 'https' || uri.host.isEmpty)) {
      throw StateError(
        '$key must use your deployed HTTPS server for release builds',
      );
    }
    return value;
  }

  static String get baseUrl =>
      _url('API_BASE_URL', const String.fromEnvironment('API_BASE_URL'));
  static String get socketUrl =>
      _url('SOCKET_URL', const String.fromEnvironment('SOCKET_URL'));
  static String get frontendUrl =>
      _url('FRONTEND_URL', const String.fromEnvironment('FRONTEND_URL'));
  static String get publicBaseUrl =>
      _url('PUBLIC_BASE_URL', const String.fromEnvironment('PUBLIC_BASE_URL'));
}
