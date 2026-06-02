import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminRoleAccessScreen extends StatelessWidget {
  const SuperAdminRoleAccessScreen({super.key});
  static const routeName = '/super-admin/role-access';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Role Access',
    icon: Icons.rule,
    description: 'Create admins and manage permission toggles.',
  );
}
