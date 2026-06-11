import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/delivery_provider.dart';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});
  static const routeName = '/delivery/active-order';

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = context.watch<DeliveryProvider>().activeOrder;
    if (order == null) {
      return const Scaffold(body: Center(child: Text('No active order')));
    }
    final provider = context.read<DeliveryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Active Order')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _line('Order ID', order.displayOrderId),
          _line('Customer name', order.customerName),
          _line('Customer phone', order.customerPhone),
          _line('Customer address', order.customerAddress),
          _line('Ordered items', order.items.map((e) => '${e.name} x${e.quantity}').join(', ')),
          _line('Payment method', order.paymentType),
          if (order.isCod) _line('COD amount', '₹${order.codAmount?.toStringAsFixed(2) ?? order.totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => _openMap(order.customerAddress), child: const Text('Open Google Maps')),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: () => _call(order.customerPhone), child: const Text('Call customer')),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: provider.markPickedUp, child: const Text('Mark Picked Up')),
          const SizedBox(height: 12),
          TextFormField(controller: _otpController, decoration: const InputDecoration(labelText: 'Enter Delivery OTP')),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final message = await provider.markDelivered(_otpController.text.trim());
              if (!context.mounted) return;
              if (message != null && message.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
              }
            },
            child: const Text('Mark Delivered'),
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text('$label: $value'),
  );

  Future<void> _openMap(String address) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }
}
