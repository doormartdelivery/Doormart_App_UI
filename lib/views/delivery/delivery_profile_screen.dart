import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class DeliveryProfileScreen extends StatelessWidget {
  const DeliveryProfileScreen({super.key});
  static const routeName = '/delivery/profile';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Delivery Profile',
    icon: Icons.person_pin,
    description: 'Delivery partner profile and vehicle details.',
  );
}
