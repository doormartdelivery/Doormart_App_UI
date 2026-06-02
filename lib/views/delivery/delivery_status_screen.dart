import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class DeliveryStatusScreen extends StatelessWidget {
  const DeliveryStatusScreen({super.key});
  static const routeName = '/delivery/status';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Delivery Status',
    icon: Icons.timeline,
    description:
        'Accepted, picked up, out for delivery, delivered status buttons.',
  );
}
