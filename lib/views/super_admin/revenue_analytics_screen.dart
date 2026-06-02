import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/animated_chart.dart';
import '../app_page.dart';

class RevenueAnalyticsScreen extends StatelessWidget {
  const RevenueAnalyticsScreen({super.key});

  static const routeName = '/super-admin/revenue';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Revenue analytics',
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: context.read<AppState>().superAdminAnalytics(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final data = snapshot.data!;
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.currency_rupee),
                  title: Text('Revenue Rs ${data['revenue'] ?? 0}'),
                  subtitle: Text('Profit Rs ${data['profit'] ?? 0}'),
                ),
                ListTile(
                  leading: const Icon(Icons.delivery_dining),
                  title: Text('${data['orderCount'] ?? 0} orders'),
                  subtitle: Text(
                    'Delivery cost Rs ${data['deliveryCost'] ?? 0}',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(
          height: 140,
          child: AnimatedChart(values: [80, 52, 108, 96, 132]),
        ),
      ],
    );
  }
}
