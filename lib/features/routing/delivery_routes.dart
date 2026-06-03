import 'package:flutter/material.dart';

import '../../views/delivery/delivery_earnings_screen.dart';
import '../../views/delivery/delivery_home_screen.dart';
import '../../views/delivery/delivery_login_screen.dart';
import '../../views/delivery/delivery_order_screen.dart';
import '../../views/delivery/live_tracking_screen.dart';

class DeliveryRoutes {
  static Map<String, WidgetBuilder> get routes => {
    DeliveryLoginScreen.routeName: (_) => const DeliveryLoginScreen(),
    DeliveryHomeScreen.routeName: (_) => const DeliveryHomeScreen(),
    DeliveryOrderScreen.routeName: (_) => const DeliveryOrderScreen(),
    LiveTrackingScreen.routeName: (_) => const LiveTrackingScreen(),
    DeliveryEarningsScreen.routeName: (_) => const DeliveryEarningsScreen(),
  };
}
