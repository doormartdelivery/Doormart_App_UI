import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminUsersScreen extends StatelessWidget {
  const SuperAdminUsersScreen({super.key});
  static const routeName = '/super-admin/users';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Super Admin Users',
    icon: Icons.group,
    description: 'Full user management across the platform.',
  );
}
