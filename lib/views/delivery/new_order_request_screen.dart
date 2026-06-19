import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class NewOrderRequestScreen extends StatefulWidget {
  const NewOrderRequestScreen({super.key, required this.orderId});

  static const routeName = '/delivery/new-order-request';
  final String orderId;

  @override
  State<NewOrderRequestScreen> createState() => _NewOrderRequestScreenState();
}

class _NewOrderRequestScreenState extends State<NewOrderRequestScreen> {
  late Future<OrderModel> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _load();
  }

  Future<OrderModel> _load() async {
    final response = await context.read<AppState>().apiService.get(
          '/orders/${widget.orderId}',
          token: context.read<AppState>().token,
        );
    return OrderModel.fromJson(response as Map<String, dynamic>);
  }

  Future<void> _accept(OrderModel order) async {
    await context.read<AppState>().acceptDeliveryOrder(order.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _reject(OrderModel order) async {
    await context.read<AppState>().apiService.post(
      '/delivery/reject/${order.id}',
      token: context.read<AppState>().token,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'New Order Request',
      children: [
        FutureBuilder<OrderModel>(
          future: _orderFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final order = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id}'),
                const SizedBox(height: 8),
                Text('Amount ₹${order.total.toStringAsFixed(0)}'),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _accept(order),
                        child: const Text('Accept'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reject(order),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
