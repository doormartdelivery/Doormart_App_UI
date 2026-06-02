import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/order_status_widget.dart';
import '../app_page.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  static const routeName = '/order-success';

  @override
  Widget build(BuildContext context) {
    return const AppPage(title: 'Order placed', children: [_SuccessContent()]);
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent();

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    final latest = orders.isEmpty ? null : orders.first;
    return Column(
      children: [
        const Icon(Icons.check_circle, size: 88, color: Colors.green),
        const SizedBox(height: 16),
        Text(
          latest == null
              ? 'Your groceries are on the way'
              : 'Order ${latest.id} confirmed',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const OrderStatusWidget(activeStep: 0),
      ],
    );
  }
}
