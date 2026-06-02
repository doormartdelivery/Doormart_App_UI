import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class DeliveryOrderDetailsScreen extends StatelessWidget {
  const DeliveryOrderDetailsScreen({super.key});
  static const routeName = '/delivery/order-details';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Delivery Order Details',
    icon: Icons.receipt,
    description:
        'Order items, pickup address, customer contact, and payment type.',
  );
}
