class AuditLogService {
  final List<String> _events = [];

  List<String> get events => List.unmodifiable(_events);

  void record(String event) {
    _events.add('${DateTime.now().toIso8601String()} $event');
  }
}
