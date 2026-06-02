import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminSettingsScreen extends StatelessWidget {
  const SuperAdminSettingsScreen({super.key});
  static const routeName = '/super-admin/settings';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Super Admin Settings',
    icon: Icons.settings_applications,
    description: 'App settings, access control, reports, and integrations.',
  );
}
