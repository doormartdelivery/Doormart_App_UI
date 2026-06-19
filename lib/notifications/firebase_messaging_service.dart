import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../services/api_service.dart';
import '../firebase_options.dart';
import 'notification_payload.dart';
import 'notification_service.dart';

class FirebaseMessagingService {
  FirebaseMessagingService({
    ApiService? apiService,
  }) : apiService = apiService ?? ApiService();

  final ApiService apiService;
  bool _initialized = false;
  bool _tokenListenerRegistered = false;

  Future<void> initialize({
    required Future<void> Function(NotificationPayload payload) onTap,
  }) async {
    if (_initialized) return;

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await NotificationService.instance.initialize(
      onTap: (payload) => unawaited(onTap(payload)),
    );

    FirebaseMessaging.onMessage.listen((message) async {
      final payload = _payloadFromMessage(message);
      if (payload != null) {
        await NotificationService.instance.showDeliveryRequest(
          orderId: payload.orderId,
          title: payload.title,
          body: payload.body,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final payload = _payloadFromMessage(message);
      if (payload != null) {
        unawaited(onTap(payload));
      }
    });

    final initialMessage = await messaging.getInitialMessage();
    final initialPayload = initialMessage == null
        ? null
        : _payloadFromMessage(initialMessage);
    if (initialPayload != null) {
      await onTap(initialPayload);
    }

    _initialized = true;
  }

  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  Future<void> saveToken({
    required String token,
    required String authToken,
  }) {
    return apiService.post(
      '/delivery/save-fcm-token',
      token: authToken,
      body: {'token': token},
    );
  }

  Future<void> registerTokenSync({
    required String authToken,
  }) async {
    final token = await getToken();
    if (token != null && token.isNotEmpty) {
      await saveToken(token: token, authToken: authToken);
    }

    if (_tokenListenerRegistered) return;
    _tokenListenerRegistered = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      unawaited(saveToken(token: newToken, authToken: authToken));
    });
  }

  NotificationPayload? _payloadFromMessage(RemoteMessage message) {
    final data = message.data;
    final orderId = data['orderId']?.toString();
    if (orderId == null || orderId.isEmpty) return null;

    return NotificationPayload(
      orderId: orderId,
      title: data['title']?.toString() ?? message.notification?.title ?? 'New Delivery Request',
      body: data['body']?.toString() ?? message.notification?.body ?? '',
    );
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}
