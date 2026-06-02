import 'package:flutter/material.dart';

import '../../widgets/dashboard_card.dart';
import '../admin/admin_dashboard_screen.dart';
import '../app_page.dart';
import 'delivery_analytics_screen.dart';
import 'payout_tracking_screen.dart';
import 'reports_screen.dart';
import 'revenue_analytics_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  const SuperAdminDashboardScreen({super.key});

  static const routeName = '/super-admin';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Super admin',
      children: [
        DashboardCard(
          title: 'Admin features',
          value: 'Included',
          icon: Icons.admin_panel_settings,
          onTap: () =>
              Navigator.pushNamed(context, AdminDashboardScreen.routeName),
        ),
        DashboardCard(
          title: 'Revenue analytics',
          value: 'Full access',
          icon: Icons.query_stats,
          onTap: () =>
              Navigator.pushNamed(context, RevenueAnalyticsScreen.routeName),
        ),
        DashboardCard(
          title: 'Payout tracking',
          value: 'Razorpay',
          icon: Icons.account_balance_wallet,
          onTap: () =>
              Navigator.pushNamed(context, PayoutTrackingScreen.routeName),
        ),
        DashboardCard(
          title: 'Reports',
          value: 'CSV and PDF',
          icon: Icons.description,
          onTap: () => Navigator.pushNamed(context, ReportsScreen.routeName),
        ),
        DashboardCard(
          title: 'Delivery analytics',
          value: 'Heatmap ready',
          icon: Icons.map,
          onTap: () =>
              Navigator.pushNamed(context, DeliveryAnalyticsScreen.routeName),
        ),
      ],
    );
  }
}
