import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});
  static const routeName = '/admin/settings';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Admin Settings',
    icon: Icons.settings,
    description: 'Store, notification, and role settings.',
  );
}
