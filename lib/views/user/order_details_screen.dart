import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key});
  static const routeName = '/order-details';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Order Details',
    icon: Icons.fact_check,
    description: 'Order items, payment, address, and delivery timeline.',
  );
}
