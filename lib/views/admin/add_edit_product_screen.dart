import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class AddEditProductScreen extends StatelessWidget {
  const AddEditProductScreen({super.key});
  static const routeName = '/admin/products/edit';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Add Edit Product',
    icon: Icons.add_box,
    description: 'Product form with image, stock, MRP, and original price.',
  );
}
