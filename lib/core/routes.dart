import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/routing/admin_routes.dart';
import '../features/routing/customer_routes.dart';
import '../features/routing/delivery_routes.dart';
import '../features/routing/shared_routes.dart';
import '../features/routing/super_admin_routes.dart';
import '../features/routing/vendor_routes.dart';
import '../providers/app_state.dart';
import '../views/access_denied_screen.dart';
import '../views/delivery/new_order_request_screen.dart';
import '../views/user/splash_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    ...SharedRoutes.routes,
    ...CustomerRoutes.routes,
    ...DeliveryRoutes.routes,
    ...AdminRoutes.routes,
    ...SuperAdminRoutes.routes,
    ...VendorRoutes.routes,
  };

  static Route<dynamic> onGenerateRoute(
    BuildContext context,
    RouteSettings settings,
  ) {
    final routeName = settings.name ?? '';
    if (routeName == NewOrderRequestScreen.routeName) {
      final orderId = settings.arguments as String? ?? '';
      return MaterialPageRoute(
        builder: (_) => NewOrderRequestScreen(orderId: orderId),
        settings: settings,
      );
    }

    final builder = routes[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        builder: (_) => const AccessDeniedScreen(),
        settings: settings,
      );
    }

    final state = context.read<AppState>();
    if (!state.initialized && settings.name != SplashScreen.routeName) {
      return MaterialPageRoute(
        builder: (_) => const SplashScreen(),
        settings: const RouteSettings(name: SplashScreen.routeName),
      );
    }
    if (!state.canAccessRoute(routeName)) {
      return MaterialPageRoute(
        builder: (_) => const AccessDeniedScreen(),
        settings: settings,
      );
    }

    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
