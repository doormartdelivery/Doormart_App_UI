import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'notifications/firebase_messaging_service.dart';
import 'notifications/notification_payload.dart';
import 'providers/app_state.dart';
import 'features/delivery/providers/delivery_provider.dart';
import 'views/user/splash_screen.dart';
import 'views/select_role_screen.dart';

class DoormartDeliveryApp extends StatefulWidget {
  const DoormartDeliveryApp({super.key});

  @override
  State<DoormartDeliveryApp> createState() => _DoormartDeliveryAppState();

  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static final navigatorKey = GlobalKey<NavigatorState>();
}

class _DoormartDeliveryAppState extends State<DoormartDeliveryApp> {
  final FirebaseMessagingService _messagingService = FirebaseMessagingService();
  bool _notificationReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _notificationReady) return;
      await _messagingService.initialize(
        onTap: (NotificationPayload payload) async {
          DoormartDeliveryApp.navigatorKey.currentState?.pushNamed(
            '/delivery/new-order-request',
            arguments: payload.orderId,
          );
        },
      );
      _notificationReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..bootstrap(),
      child: ChangeNotifierProvider(
        create: (_) => DeliveryProvider(),
        child: Consumer<AppState>(
          builder: (context, state, child) => MaterialApp(
            title: 'Doormart Delivery',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: DoormartDeliveryApp.scaffoldMessengerKey,
            navigatorKey: DoormartDeliveryApp.navigatorKey,
            theme: AppTheme.lightTheme,
            initialRoute: kIsWeb
                ? SelectRoleScreen.routeName
                : SplashScreen.routeName,
            onGenerateRoute: (settings) =>
                AppRoutes.onGenerateRoute(context, settings),
          ),
        ),
      ),
    );
  }
}
