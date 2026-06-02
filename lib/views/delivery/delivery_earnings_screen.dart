import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/dashboard_card.dart';
import '../app_page.dart';

class DeliveryEarningsScreen extends StatelessWidget {
  const DeliveryEarningsScreen({super.key});
  static const routeName = '/delivery/earnings';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Delivery Earnings',
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: context.read<AppState>().deliveryEarnings(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final data = snapshot.data!;
            return Column(
              children: [
                DashboardCard(
                  title: 'Today',
                  value: 'Rs ${data['today'] ?? 0}',
                  icon: Icons.today,
                ),
                DashboardCard(
                  title: 'Weekly',
                  value: 'Rs ${data['weekly'] ?? 0}',
                  icon: Icons.calendar_view_week,
                ),
                DashboardCard(
                  title: 'Monthly',
                  value: 'Rs ${data['monthly'] ?? 0}',
                  icon: Icons.calendar_month,
                ),
                DashboardCard(
                  title: 'Pending payout',
                  value: 'Rs ${data['pendingPayout'] ?? 0}',
                  icon: Icons.account_balance_wallet,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
