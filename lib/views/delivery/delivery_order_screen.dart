import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/order_status_widget.dart';
import '../app_page.dart';

class DeliveryOrderScreen extends StatelessWidget {
  const DeliveryOrderScreen({super.key});

  static const routeName = '/delivery/order';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Delivery order',
      children: [
        Consumer<AppState>(
          builder: (context, state, _) {
            final orders = state.orders.take(5).toList();
            if (orders.isEmpty) {
              return const ListTile(
                leading: Icon(Icons.lock_clock),
                title: Text('Order DM-1001'),
                subtitle: Text(
                  'First delivery partner to accept locks this order',
                ),
              );
            }
            return Column(
              children: orders
                  .map(
                    (order) => ListTile(
                      leading: const Icon(Icons.lock_clock),
                      title: Text('Order ${order.id}'),
                      subtitle: Text(
                        '${order.status.name} | Rs ${order.total.toStringAsFixed(0)}',
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        const OrderStatusWidget(activeStep: 1),
      ],
    );
  }
}
