import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminLoginScreen extends StatelessWidget {
  const SuperAdminLoginScreen({super.key});
  static const routeName = '/super-admin/login';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Super Admin Login',
    icon: Icons.security,
    description: 'Secure super admin email/password login.',
  );
}
