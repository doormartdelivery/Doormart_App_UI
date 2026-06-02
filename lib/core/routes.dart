import 'package:flutter/material.dart';

import '../views/admin/admin_dashboard_screen.dart';
import '../views/admin/admin_notifications_screen.dart';
import '../views/admin/admin_orders_screen.dart';
import '../views/admin/audit_logs_screen.dart';
import '../views/admin/manage_delivery_screen.dart';
import '../views/admin/manage_products_screen.dart';
import '../views/admin/manage_users_screen.dart';
import '../views/admin/stock_screen.dart';
import '../views/delivery/delivery_earnings_screen.dart';
import '../views/delivery/delivery_home_screen.dart';
import '../views/delivery/delivery_order_screen.dart';
import '../views/delivery/live_tracking_screen.dart';
import '../views/super_admin/delivery_analytics_screen.dart';
import '../views/super_admin/payout_tracking_screen.dart';
import '../views/super_admin/reports_screen.dart';
import '../views/super_admin/revenue_analytics_screen.dart';
import '../views/super_admin/super_admin_dashboard_screen.dart';
import '../views/super_admin/super_admin_heatmap_screen.dart';
import '../views/super_admin/super_admin_orders_screen.dart';
import '../views/user/address_screen.dart';
import '../views/user/cart_screen.dart';
import '../views/user/checkout_screen.dart';
import '../views/user/my_orders_screen.dart';
import '../views/user/notification_screen.dart';
import '../views/user/order_success_screen.dart';
import '../views/user/product_category_screen.dart';
import '../views/user/product_list_screen.dart';
import '../views/user/profile_screen.dart';
import '../views/user/scheduled_order_screen.dart';
import '../views/user/user_home_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> get routes => {
    UserHomeScreen.routeName: (_) => const UserHomeScreen(),
    ProductListScreen.routeName: (_) => const ProductListScreen(),
    ProductCategoryScreen.routeName: (_) => const ProductCategoryScreen(),
    CartScreen.routeName: (_) => const CartScreen(),
    CheckoutScreen.routeName: (_) => const CheckoutScreen(),
    OrderSuccessScreen.routeName: (_) => const OrderSuccessScreen(),
    ScheduledOrderScreen.routeName: (_) => const ScheduledOrderScreen(),
    MyOrdersScreen.routeName: (_) => const MyOrdersScreen(),
    AddressScreen.routeName: (_) => const AddressScreen(),
    NotificationScreen.routeName: (_) => const NotificationScreen(),
    ProfileScreen.routeName: (_) => const ProfileScreen(),
    DeliveryHomeScreen.routeName: (_) => const DeliveryHomeScreen(),
    DeliveryOrderScreen.routeName: (_) => const DeliveryOrderScreen(),
    LiveTrackingScreen.routeName: (_) => const LiveTrackingScreen(),
    DeliveryEarningsScreen.routeName: (_) => const DeliveryEarningsScreen(),
    AdminDashboardScreen.routeName: (_) => const AdminDashboardScreen(),
    AdminOrdersScreen.routeName: (_) => const AdminOrdersScreen(),
    AdminNotificationsScreen.routeName: (_) => const AdminNotificationsScreen(),
    ManageProductsScreen.routeName: (_) => const ManageProductsScreen(),
    ManageUsersScreen.routeName: (_) => const ManageUsersScreen(),
    ManageDeliveryScreen.routeName: (_) => const ManageDeliveryScreen(),
    StockScreen.routeName: (_) => const StockScreen(),
    AuditLogsScreen.routeName: (_) => const AuditLogsScreen(),
    SuperAdminDashboardScreen.routeName: (_) =>
        const SuperAdminDashboardScreen(),
    RevenueAnalyticsScreen.routeName: (_) => const RevenueAnalyticsScreen(),
    PayoutTrackingScreen.routeName: (_) => const PayoutTrackingScreen(),
    ReportsScreen.routeName: (_) => const ReportsScreen(),
    DeliveryAnalyticsScreen.routeName: (_) => const DeliveryAnalyticsScreen(),
    SuperAdminOrdersScreen.routeName: (_) => const SuperAdminOrdersScreen(),
    SuperAdminHeatmapScreen.routeName: (_) => const SuperAdminHeatmapScreen(),
  };
}
