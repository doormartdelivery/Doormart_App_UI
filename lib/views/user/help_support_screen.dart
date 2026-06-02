import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});
  static const routeName = '/help';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Help Support',
    icon: Icons.support_agent,
    description: 'Customer support, FAQs, and order issue help.',
  );
}
