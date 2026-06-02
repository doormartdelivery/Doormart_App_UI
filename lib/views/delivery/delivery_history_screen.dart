import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class DeliveryHistoryScreen extends StatelessWidget {
  const DeliveryHistoryScreen({super.key});
  static const routeName = '/delivery/history';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Delivery History',
    icon: Icons.history,
    description: 'Completed delivery history and performance.',
  );
}
