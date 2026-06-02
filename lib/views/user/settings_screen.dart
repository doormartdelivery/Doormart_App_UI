import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Settings',
    icon: Icons.settings,
    description: 'Language, notifications, theme, and account settings.',
  );
}
