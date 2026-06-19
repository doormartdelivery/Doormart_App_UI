import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/delivery/models/delivery_order_model.dart';
import '../../features/delivery/providers/delivery_provider.dart';
import '../../features/delivery/services/delivery_api_service.dart';
import '../app_page.dart';
import '../access_denied_screen.dart';

class NewOrderRequestScreen extends StatefulWidget {
  const NewOrderRequestScreen({super.key, required this.orderId});

  static const routeName = '/delivery/new-order-request';
  final String orderId;

  @override
  State<NewOrderRequestScreen> createState() => _NewOrderRequestScreenState();
}

class _NewOrderRequestScreenState extends State<NewOrderRequestScreen> {
  late Future<DeliveryOrderModel> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = _load();
  }

  Future<DeliveryOrderModel> _load() async {
    final provider = context.read<DeliveryProvider>();
    final token = provider.authToken;
    if (token == null || token.isEmpty) {
      throw StateError('Delivery session not found. Please log in again.');
    }
    final response = await DeliveryApiService().fetchOrderById(
      orderId: widget.orderId,
      token: token,
    );
    final orderJson = response['order'];
    if (orderJson is! Map<String, dynamic>) {
      throw StateError('Invalid order response');
    }
    return DeliveryOrderModel.fromJson(orderJson);
  }

  Future<void> _accept(DeliveryOrderModel order) async {
    final provider = context.read<DeliveryProvider>();
    await provider.apiService.acceptOrder(
      orderId: order.id,
      deliveryPersonId: provider.deliveryPerson?.id ?? '',
      token: provider.authToken,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _reject(DeliveryOrderModel order) async {
    final provider = context.read<DeliveryProvider>();
    await provider.apiService.rejectOrder(
      orderId: order.id,
      deliveryPersonId: provider.deliveryPerson?.id ?? '',
      token: provider.authToken,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    if (provider.authToken == null || provider.authToken!.isEmpty) {
      return const AccessDeniedScreen();
    }

    return AppPage(
      title: 'New Order Request',
      children: [
        FutureBuilder<DeliveryOrderModel>(
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
                Text('Order #${order.displayOrderId}'),
                const SizedBox(height: 8),
                Text('Amount ₹${order.totalAmount.toStringAsFixed(0)}'),
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
