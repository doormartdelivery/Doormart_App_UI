import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/delivery_provider.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});
  static const routeName = '/delivery/history';
  @override
  Widget build(BuildContext context) {
    final history = context.watch<DeliveryProvider>().history;
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery History')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (_, index) {
          final order = history[index];
          return Card(
            child: ListTile(
              title: Text(order.displayOrderId),
              subtitle: Text('${order.createdAt} • ${order.customerArea} • ${order.paymentType}'),
              trailing: Text('₹${(order.deliveryEarning ?? 0).toStringAsFixed(2)}'),
            ),
          );
        },
      ),
    );
  }
}
