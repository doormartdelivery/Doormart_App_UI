import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key});
  static const routeName = '/product-details';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Product Details',
    icon: Icons.inventory_2,
    description:
        'Image, price, MRP, discount, stock, quantity selector, and similar products.',
  );
}
