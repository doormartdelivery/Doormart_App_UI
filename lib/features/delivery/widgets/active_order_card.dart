import 'package:flutter/material.dart';

import '../models/delivery_order_model.dart';

class ActiveOrderCard extends StatelessWidget {
  const ActiveOrderCard({super.key, required this.order});

  final DeliveryOrderModel order;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ${order.displayOrderId}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(order.customerName),
            Text(order.customerPhone),
            Text(order.customerAddress),
            Text('Items: ${order.itemCount}'),
          ],
        ),
      ),
    );
  }
}
