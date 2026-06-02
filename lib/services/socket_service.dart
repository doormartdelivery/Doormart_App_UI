class SocketService {
  bool _connected = false;

  bool get connected => _connected;

  Future<void> connect() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _connected = true;
  }

  void emitLocationUpdate(double latitude, double longitude) {}

  void disconnect() {
    _connected = false;
  }
}
