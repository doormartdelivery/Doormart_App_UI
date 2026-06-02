import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../../widgets/order_card.dart';
import '../app_page.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});
  static const routeName = '/admin/orders';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Admin Orders',
      children: [
        FutureBuilder(
          future: context.read<AppState>().allOrdersForRole(UserRoles.admin),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final orders = snapshot.data!;
            if (orders.isEmpty) return const Text('No orders');
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
