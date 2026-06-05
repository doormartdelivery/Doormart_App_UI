import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/dashboard_card.dart';
import '../app_page.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_order_screen.dart';
import 'live_tracking_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  static const routeName = '/delivery';

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  late Future<List<OrderModel>> _openOrdersFuture;

  @override
  void initState() {
    super.initState();
    _openOrdersFuture = _loadOpenOrders();
  }

  Future<List<OrderModel>> _loadOpenOrders() {
    return context.read<AppState>().availableDeliveryOrders();
  }

  Future<void> _openOrders() async {
    await Navigator.pushNamed(context, DeliveryOrderScreen.routeName);
    if (!mounted) return;
    setState(() => _openOrdersFuture = _loadOpenOrders());
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Delivery',
      children: [
        FutureBuilder<List<OrderModel>>(
          future: _openOrdersFuture,
          builder: (context, snapshot) {
            final value = snapshot.hasData
                ? _openOrdersLabel(snapshot.data!.length)
                : snapshot.hasError
                    ? '0 waiting'
                    : 'Loading';

            return DashboardCard(
              title: 'Open orders',
              value: value,
              icon: Icons.notifications_active,
              onTap: _openOrders,
            );
          },
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

String _openOrdersLabel(int count) {
  return count == 1 ? '1 waiting' : '$count waiting';
}
