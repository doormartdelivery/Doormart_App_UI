import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SuperAdminAuditLogsScreen extends StatelessWidget {
  const SuperAdminAuditLogsScreen({super.key});
  static const routeName = '/super-admin/audit-logs';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Super Admin Audit Logs',
    icon: Icons.history,
    description: 'Admin and super admin action history.',
  );
}
