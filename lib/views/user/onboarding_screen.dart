import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});
  static const routeName = '/onboarding';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Onboarding',
    icon: Icons.swipe,
    description:
        'Three slides for fast grocery delivery, secure payments, and live tracking.',
  );
}
