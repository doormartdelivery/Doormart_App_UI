import 'package:flutter/material.dart';

import '../../views/admin/admin_dashboard_screen.dart';
import '../../views/admin/admin_login_screen.dart';
import '../../views/admin/admin_notifications_screen.dart';
import '../../views/admin/admin_orders_screen.dart';
import '../../views/admin/manage_categories_screen.dart';
import '../../views/admin/audit_logs_screen.dart';
import '../../views/admin/manage_delivery_screen.dart';
import '../../views/admin/manage_products_screen.dart';
import '../../views/admin/manage_users_screen.dart';
import '../../views/admin/stock_screen.dart';

class AdminRoutes {
  static Map<String, WidgetBuilder> get routes => {
    AdminLoginScreen.routeName: (_) => const AdminLoginScreen(),
    AdminDashboardScreen.routeName: (_) => const AdminDashboardScreen(),
    AdminOrdersScreen.routeName: (_) => const AdminOrdersScreen(),
    AdminNotificationsScreen.routeName: (_) => const AdminNotificationsScreen(),
    ManageProductsScreen.routeName: (_) => const ManageProductsScreen(),
    ManageCategoriesScreen.routeName: (_) => const ManageCategoriesScreen(),
    ManageUsersScreen.routeName: (_) => const ManageUsersScreen(),
    ManageDeliveryScreen.routeName: (_) => const ManageDeliveryScreen(),
    StockScreen.routeName: (_) => const StockScreen(),
    AuditLogsScreen.routeName: (_) => const AuditLogsScreen(),
  };
}
