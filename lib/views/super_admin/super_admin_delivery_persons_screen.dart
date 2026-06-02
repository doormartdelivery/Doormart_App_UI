import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminDeliveryPersonsScreen extends StatelessWidget {
  const SuperAdminDeliveryPersonsScreen({super.key});
  static const routeName = '/super-admin/delivery-persons';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Super Admin Delivery Persons',
    icon: Icons.delivery_dining,
    description: 'Delivery person management and payout visibility.',
  );
}
