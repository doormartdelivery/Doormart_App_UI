import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/animated_chart.dart';
import '../../widgets/dashboard_card.dart';
import '../app_page.dart';
import 'audit_logs_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'stock_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Admin dashboard',
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: context.read<AppState>().adminDashboard(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final data = snapshot.data!;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('${data['orders'] ?? 0} orders')),
                Chip(label: Text('${data['products'] ?? 0} products')),
                Chip(label: Text('${data['users'] ?? 0} users')),
                Chip(label: Text('${data['openOrders'] ?? 0} open')),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        DashboardCard(
          title: 'Orders',
          value: 'Track and assign',
          icon: Icons.receipt_long,
          onTap: () =>
              Navigator.pushNamed(context, AdminOrdersScreen.routeName),
        ),
        DashboardCard(
          title: 'Notifications',
          value: 'Stock and delay alerts',
          icon: Icons.notifications_active,
          onTap: () =>
              Navigator.pushNamed(context, AdminNotificationsScreen.routeName),
        ),
        DashboardCard(
          title: 'Products',
          value: 'Add, edit, delete',
          icon: Icons.inventory_2,
          onTap: () =>
              Navigator.pushNamed(context, ManageProductsScreen.routeName),
        ),
        DashboardCard(
          title: 'Users',
          value: 'Role-based access',
          icon: Icons.group,
          onTap: () =>
              Navigator.pushNamed(context, ManageUsersScreen.routeName),
        ),
        DashboardCard(
          title: 'Delivery partners',
          value: 'Assignments and status',
          icon: Icons.delivery_dining,
          onTap: () =>
              Navigator.pushNamed(context, ManageDeliveryScreen.routeName),
        ),
        DashboardCard(
          title: 'Stock alerts',
          value: 'Low inventory',
          icon: Icons.warning_amber,
          onTap: () => Navigator.pushNamed(context, StockScreen.routeName),
        ),
        DashboardCard(
          title: 'Audit logs',
          value: 'Critical actions',
          icon: Icons.history,
          onTap: () => Navigator.pushNamed(context, AuditLogsScreen.routeName),
        ),
        const SizedBox(height: 18),
        const SizedBox(
          height: 140,
          child: AnimatedChart(values: [52, 88, 40, 96, 72]),
        ),
      ],
    );
  }
}
