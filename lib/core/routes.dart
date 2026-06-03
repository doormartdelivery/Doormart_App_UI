import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/routing/admin_routes.dart';
import '../features/routing/customer_routes.dart';
import '../features/routing/delivery_routes.dart';
import '../features/routing/shared_routes.dart';
import '../features/routing/super_admin_routes.dart';
import '../providers/app_state.dart';
import '../views/access_denied_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    ...SharedRoutes.routes,
    ...CustomerRoutes.routes,
    ...DeliveryRoutes.routes,
    ...AdminRoutes.routes,
    ...SuperAdminRoutes.routes,
  };

  static Route<dynamic> onGenerateRoute(
    BuildContext context,
    RouteSettings settings,
  ) {
    final builder = routes[settings.name];
    if (builder == null) {
      return MaterialPageRoute(
        builder: (_) => const AccessDeniedScreen(),
        settings: settings,
      );
    }

    final state = context.read<AppState>();
    final routeName = settings.name ?? '';
    if (!state.canAccessRoute(routeName)) {
      return MaterialPageRoute(
        builder: (_) => const AccessDeniedScreen(),
        settings: settings,
      );
    }

    return MaterialPageRoute(builder: builder, settings: settings);
  }
}
