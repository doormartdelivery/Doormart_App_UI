import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});
  static const routeName = '/admin/login';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Admin Login',
    icon: Icons.admin_panel_settings,
    description: 'Secure admin email/password login.',
  );
}
