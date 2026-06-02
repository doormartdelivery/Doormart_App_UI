import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Doormartdelivery',
    icon: Icons.local_grocery_store,
    description: 'Splash with logo, app name, and walking mascot.',
  );
}
