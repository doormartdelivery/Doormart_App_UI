import 'package:flutter/material.dart';

import '../../widgets/dashboard_card.dart';
import '../app_page.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_order_screen.dart';
import 'live_tracking_screen.dart';

class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  static const routeName = '/delivery';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Delivery',
      children: [
        DashboardCard(
          title: 'Open orders',
          value: '4 waiting',
          icon: Icons.notifications_active,
          onTap: () =>
              Navigator.pushNamed(context, DeliveryOrderScreen.routeName),
        ),
        DashboardCard(
          title: 'Live tracking',
          value: 'Socket ready',
          icon: Icons.location_on,
          onTap: () =>
              Navigator.pushNamed(context, LiveTrackingScreen.routeName),
        ),
        DashboardCard(
          title: 'Earnings',
          value: 'Payout status',
          icon: Icons.account_balance_wallet,
          onTap: () =>
              Navigator.pushNamed(context, DeliveryEarningsScreen.routeName),
        ),
      ],
    );
  }
}
