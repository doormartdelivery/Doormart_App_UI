import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});
  static const routeName = '/wishlist';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Wishlist',
    icon: Icons.favorite,
    description: 'Saved grocery items for quick repeat orders.',
  );
}
