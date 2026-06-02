import '../constants/api_constants.dart';

class EnvConfig {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: ApiConstants.baseUrl,
  );
}
