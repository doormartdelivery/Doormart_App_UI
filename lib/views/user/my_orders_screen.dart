import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/order_card.dart';
import '../app_page.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});
  static const routeName = '/my-orders';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'My Orders',
      children: [
        Consumer<AppState>(
          builder: (context, state, _) {
            final orders = state.orders;
            if (orders.isEmpty) return const Text('No orders yet');
            return Column(
              children: orders
                  .map(
                    (order) => OrderCard(
                      orderId: order.id,
                      status:
                          '${order.status.name} | Rs ${order.total.toStringAsFixed(0)}',
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
