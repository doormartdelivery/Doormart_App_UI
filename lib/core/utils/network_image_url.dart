import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';

class NetworkImageUrl {
  const NetworkImageUrl._();

  static String normalize(String? rawUrl) {
    final value = (rawUrl ?? '')
        .replaceAll(RegExp(r'[\s\u0000-\u001F\u007F\u200B-\u200D\uFEFF]+'), '')
        .trim();
    if (value.isEmpty) return '';

    var assetValue = value;
    while (assetValue.startsWith('assets/assets/')) {
      assetValue = assetValue.substring('assets/'.length);
    }
    if (assetValue == 'assets/images/categories/baby.png') {
      assetValue = 'assets/images/categories/baby_care.png';
    }
    if (assetValue.startsWith('assets/') || assetValue.startsWith('data:')) {
      return assetValue;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) return value;

    final isLocalHost = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (isLocalHost) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        return uri.replace(host: '10.0.2.2').toString();
      }
      return uri.toString();
    }

    if (uri.host == 'res.cloudinary.com') {
      final baseUri = Uri.parse(ApiConstants.publicBaseUrl);
      final origin = baseUri.replace(path: '', query: '', fragment: '');
      return origin
          .resolveUri(
            Uri(path: '/api/media/proxy', queryParameters: {'url': value}),
          )
          .toString();
    }

    if (value.startsWith('/uploads/')) {
      final baseUri = Uri.parse(ApiConstants.publicBaseUrl);
      final origin = baseUri.replace(path: '', query: '', fragment: '');
      return origin.resolve(value).toString();
    }

    return value;
  }
}
