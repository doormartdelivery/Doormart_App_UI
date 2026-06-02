import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class AdminAssignDeliveryScreen extends StatelessWidget {
  const AdminAssignDeliveryScreen({super.key});
  static const routeName = '/admin/assign-delivery';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Assign Delivery',
    icon: Icons.assignment_ind,
    description: 'Assign or reassign delivery partners to orders.',
  );
}
