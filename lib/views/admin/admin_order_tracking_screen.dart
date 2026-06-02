import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class AdminOrderTrackingScreen extends StatelessWidget {
  const AdminOrderTrackingScreen({super.key});
  static const routeName = '/admin/order-tracking';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Admin Order Tracking',
    icon: Icons.map,
    description: 'Monitor order and delivery movement.',
  );
}
