import 'package:flutter/material.dart';

import '../app_page.dart';

class DeliveryAnalyticsScreen extends StatelessWidget {
  const DeliveryAnalyticsScreen({super.key});

  static const routeName = '/super-admin/delivery-analytics';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Delivery analytics',
      children: [
        ListTile(
          leading: Icon(Icons.timer),
          title: Text('Average delivery time'),
          subtitle: Text('28 minutes'),
        ),
        Card(
          child: SizedBox(
            height: 220,
            child: Center(child: Text('Delivery zone heatmap placeholder')),
          ),
        ),
      ],
    );
  }
}
