import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class NetworkImageUrl {
  const NetworkImageUrl._();

  static String normalize(String? rawUrl) {
    final value = (rawUrl ?? '').trim();
    if (value.isEmpty) return '';

    if (value.startsWith('assets/') || value.startsWith('data:')) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    final isLocalHost =
        uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (isLocalHost) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return uri.replace(host: '10.0.2.2').toString();
      }
      return uri.toString();
    }

    if (value.startsWith('/uploads/')) {
      final baseUri = Uri.parse(ApiConstants.publicBaseUrl);
      final origin = baseUri.replace(path: '', query: '', fragment: '');
      return origin.resolve(value).toString();
    }

    return value;
  }
}
