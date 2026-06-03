import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../role_login_screen.dart';

class SuperAdminLoginScreen extends StatelessWidget {
  const SuperAdminLoginScreen({super.key});
  static const routeName = '/super-admin/login';
  @override
  Widget build(BuildContext context) => const RoleLoginScreen(
    title: 'Super Admin Login',
    subtitle:
        'Super admins sign in with email and password for platform control.',
    role: UserRoles.superAdmin,
    allowPhonePassword: false,
    allowEmailPassword: true,
  );
}
