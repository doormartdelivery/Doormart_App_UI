import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class DeliverySettingsScreen extends StatelessWidget {
  const DeliverySettingsScreen({super.key});
  static const routeName = '/delivery/settings';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Delivery Settings',
    icon: Icons.settings,
    description: 'Online status, notifications, and account settings.',
  );
}
