import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class DeliveryLoginScreen extends StatelessWidget {
  const DeliveryLoginScreen({super.key});
  static const routeName = '/delivery/login';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Delivery Login',
    icon: Icons.delivery_dining,
    description: 'Delivery partner mobile/password login with JWT.',
  );
}
