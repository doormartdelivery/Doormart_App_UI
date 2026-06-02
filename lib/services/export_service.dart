class ExportService {
  String toCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final headers = rows.first.keys.toList();
    return [
      headers.join(','),
      ...rows.map((row) => headers.map((key) => row[key]).join(',')),
    ].join('\n');
  }
}
