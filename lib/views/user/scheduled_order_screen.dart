import 'package:flutter/material.dart';

import '../app_page.dart';

class ScheduledOrderScreen extends StatelessWidget {
  const ScheduledOrderScreen({super.key});

  static const routeName = '/scheduled-orders';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Scheduled orders',
      bottomNavIndex: 3,
      children: [
        ListTile(
          leading: Icon(Icons.calendar_month),
          title: Text('Milk and bread'),
          subtitle: Text('Every Monday, Wednesday, and Friday at 7 AM'),
        ),
        ListTile(
          leading: Icon(Icons.repeat),
          title: Text('Monthly staples'),
          subtitle: Text('Rice, dal, oil, and cleaning supplies'),
        ),
      ],
    );
  }
}
