import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/routes.dart';
import 'core/theme.dart';
import 'notifications/firebase_messaging_service.dart';
import 'notifications/notification_payload.dart';
import 'core/role_access.dart';
import 'providers/app_state.dart';
import 'features/delivery/providers/delivery_provider.dart';
import 'features/delivery/screens/delivery_home_screen.dart';
import 'features/delivery/screens/delivery_status_screen.dart';
import 'views/vendor/vendor_dashboard_screen.dart';
import 'views/user/user_home_screen.dart';
import 'views/user/splash_screen.dart';

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
  NotificationPayload? _pendingNotification;

  AppState? get _appState {
    final navigatorContext = DoormartDeliveryApp.navigatorKey.currentContext;
    return navigatorContext == null
        ? null
        : Provider.of<AppState>(navigatorContext, listen: false);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _notificationReady) return;
      await _messagingService.initialize(onTap: _handleNotificationTap);
      // AppState bootstraps in parallel with this widget. Retry token
      // registration after Firebase is fully initialized so a startup race
      // cannot leave logged-in users out of superadmin broadcasts.
      final appState = _appState;
      if (appState?.token != null && appState!.token!.isNotEmpty) {
        try {
          await _messagingService.registerTokenSync(authToken: appState.token!);
        } catch (error) {
          debugPrint('FCM token sync skipped after Firebase init: $error');
        }
      }
      _notificationReady = true;
      _flushPendingNotification();
    });
  }

  Future<void> _handleNotificationTap(NotificationPayload payload) async {
    final navigator = DoormartDeliveryApp.navigatorKey.currentState;
    if (navigator == null) {
      _pendingNotification = payload;
      return;
    }

    final state = _appState;
    if (state == null) {
      _pendingNotification = payload;
      return;
    }
    final approvalStatus = (state.user?.approvalStatus ?? 'approved')
        .toLowerCase();
    final targetRoute =
        state.user?.role == 'delivery_person' && approvalStatus != 'approved'
        ? DeliveryStatusScreen.routeName
        : RoleAccess.dashboardForRole(state.user?.role);
    navigator.pushNamedAndRemoveUntil(switch (targetRoute) {
      DeliveryHomeScreen.routeName => DeliveryHomeScreen.routeName,
      DeliveryStatusScreen.routeName => DeliveryStatusScreen.routeName,
      VendorDashboardScreen.routeName => VendorDashboardScreen.routeName,
      _ => UserHomeScreen.routeName,
    }, (route) => route.isFirst);
  }

  void _flushPendingNotification() {
    final payload = _pendingNotification;
    if (payload == null) return;
    _pendingNotification = null;
    final navigator = DoormartDeliveryApp.navigatorKey.currentState;
    if (navigator == null) return;

    final state = _appState;
    if (state == null) return;
    final approvalStatus = (state.user?.approvalStatus ?? 'approved')
        .toLowerCase();
    final targetRoute =
        state.user?.role == 'delivery_person' && approvalStatus != 'approved'
        ? DeliveryStatusScreen.routeName
        : RoleAccess.dashboardForRole(state.user?.role);
    navigator.pushNamedAndRemoveUntil(switch (targetRoute) {
      DeliveryHomeScreen.routeName => DeliveryHomeScreen.routeName,
      DeliveryStatusScreen.routeName => DeliveryStatusScreen.routeName,
      VendorDashboardScreen.routeName => VendorDashboardScreen.routeName,
      _ => UserHomeScreen.routeName,
    }, (route) => route.isFirst);
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
            initialRoute: SplashScreen.routeName,
            onGenerateRoute: (settings) =>
                AppRoutes.onGenerateRoute(context, settings),
          ),
        ),
      ),
    );
  }
}
