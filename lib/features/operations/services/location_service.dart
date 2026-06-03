class LocationService {
  Future<({double latitude, double longitude})> currentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return (latitude: 13.0827, longitude: 80.2707);
  }
}
