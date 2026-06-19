import 'notification_payload.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> initialize({
    required void Function(NotificationPayload payload) onTap,
  }) async {}

  Future<void> showDeliveryRequest({
    required String orderId,
    required String title,
    required String body,
  }) async {}

  Future<void> handleNotificationTap(String? payload) async {}
}
