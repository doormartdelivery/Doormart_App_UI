class NotificationPayload {
  const NotificationPayload({
    required this.orderId,
    required this.title,
    required this.body,
  });

  final String orderId;
  final String title;
  final String body;

  Map<String, dynamic> toMap() => {
        'orderId': orderId,
        'title': title,
        'body': body,
      };

  factory NotificationPayload.fromMap(Map<String, dynamic> map) {
    return NotificationPayload(
      orderId: map['orderId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
    );
  }
}
