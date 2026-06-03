import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../role_login_screen.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});
  static const routeName = '/admin/login';
  @override
  Widget build(BuildContext context) => const RoleLoginScreen(
    title: 'Admin Login',
    subtitle: 'Admins sign in with email and password to manage operations.',
    role: UserRoles.admin,
    allowPhonePassword: false,
    allowEmailPassword: true,
  );
}
