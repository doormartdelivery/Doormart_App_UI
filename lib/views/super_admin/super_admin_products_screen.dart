import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminProductsScreen extends StatelessWidget {
  const SuperAdminProductsScreen({super.key});
  static const routeName = '/super-admin/products';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Super Admin Products',
    icon: Icons.inventory,
    description: 'Product, stock, cost, and selling price overview.',
  );
}
