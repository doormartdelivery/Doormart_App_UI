import 'package:flutter/material.dart';

import '../../views/super_admin/delivery_analytics_screen.dart';
import '../../views/super_admin/payout_tracking_screen.dart';
import '../../views/super_admin/reports_screen.dart';
import '../../views/super_admin/revenue_analytics_screen.dart';
import '../../views/super_admin/super_admin_dashboard_screen.dart';
import '../../views/super_admin/super_admin_heatmap_screen.dart';
import '../../views/super_admin/super_admin_login_screen.dart';
import '../../views/super_admin/super_admin_orders_screen.dart';
import '../../views/super_admin/super_admin_vendors_screen.dart';

class SuperAdminRoutes {
  static Map<String, WidgetBuilder> get routes => {
    SuperAdminLoginScreen.routeName: (_) => const SuperAdminLoginScreen(),
    SuperAdminDashboardScreen.routeName: (_) =>
        const SuperAdminDashboardScreen(),
    RevenueAnalyticsScreen.routeName: (_) => const RevenueAnalyticsScreen(),
    PayoutTrackingScreen.routeName: (_) => const PayoutTrackingScreen(),
    ReportsScreen.routeName: (_) => const ReportsScreen(),
    DeliveryAnalyticsScreen.routeName: (_) => const DeliveryAnalyticsScreen(),
    SuperAdminOrdersScreen.routeName: (_) => const SuperAdminOrdersScreen(),
    SuperAdminHeatmapScreen.routeName: (_) => const SuperAdminHeatmapScreen(),
    SuperAdminVendorsScreen.routeName: (_) => const SuperAdminVendorsScreen(),
  };
}
