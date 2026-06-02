import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});
  static const routeName = '/signup';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Signup',
    icon: Icons.person_add,
    description: 'Create a new grocery delivery customer account.',
  );
}
