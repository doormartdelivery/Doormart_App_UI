import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static const MethodChannel _channel = MethodChannel('doormart/location');

  Future<({double latitude, double longitude})> currentLocation() async {
    if (kIsWeb) {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      return (latitude: position.latitude, longitude: position.longitude);
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

  Future<String?> addressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    if (kIsWeb) {
      final response = await http.get(
        Uri.https('nominatim.openstreetmap.org', '/reverse', {
          'format': 'jsonv2',
          'lat': latitude.toString(),
          'lon': longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
        }),
        headers: const {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['display_name']?.toString().trim();
      return address == null || address.isEmpty ? null : address;
    }

    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final place = placemarks.first;
    final parts =
        [
              place.name,
              place.street,
              place.subLocality,
              place.locality,
              place.administrativeArea,
              place.postalCode,
            ]
            .whereType<String>()
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toSet()
            .toList();
    return parts.isEmpty ? null : parts.join(', ');
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
