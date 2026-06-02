class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
}
