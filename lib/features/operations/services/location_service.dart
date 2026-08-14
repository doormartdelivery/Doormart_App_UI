import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const MethodChannel _channel = MethodChannel('doormart/location');

  Future<({double latitude, double longitude})> currentLocation() async {
    if (kIsWeb) {
      throw UnsupportedError('Location capture is not supported on web');
    }

    final permission = await Permission.locationWhenInUse.request();
    if (!permission.isGranted && !permission.isLimited) {
      throw StateError('Location permission is required');
    }

    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getCurrentLocation',
    );
    final latitude = _asDouble(result?['latitude']);
    final longitude = _asDouble(result?['longitude']);
    if (latitude == null || longitude == null) {
      throw StateError('Unable to read current location');
    }
    return (latitude: latitude, longitude: longitude);
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
