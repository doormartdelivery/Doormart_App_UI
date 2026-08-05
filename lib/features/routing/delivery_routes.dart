import 'package:flutter/material.dart';

import '../delivery/screens/active_order_screen.dart';
import '../delivery/screens/delivery_history_screen.dart';
import '../delivery/screens/delivery_home_screen.dart';
import '../delivery/screens/delivery_login_screen.dart';
import '../delivery/screens/delivery_profile_screen.dart';

class DeliveryRoutes {
  static Map<String, WidgetBuilder> get routes => {
    DeliveryLoginScreen.routeName: (_) => const DeliveryLoginScreen(),
    DeliveryHomeScreen.routeName: (_) => const DeliveryHomeScreen(),
    ActiveOrderScreen.routeName: (_) => const ActiveOrderScreen(),
    DeliveryHistoryScreen.routeName: (_) => const DeliveryHistoryScreen(),
    DeliveryProfileScreen.routeName: (_) => const DeliveryProfileScreen(),
  };
}
