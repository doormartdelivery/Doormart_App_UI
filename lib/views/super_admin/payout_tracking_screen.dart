import 'package:flutter/material.dart';

import '../app_page.dart';

class PayoutTrackingScreen extends StatelessWidget {
  const PayoutTrackingScreen({super.key});

  static const routeName = '/super-admin/payouts';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Payout tracking',
      children: [
        ListTile(
          leading: Icon(Icons.verified),
          title: Text('Razorpay payout batch'),
          subtitle: Text('Pending settlement Rs 18,240'),
        ),
      ],
    );
  }
}
