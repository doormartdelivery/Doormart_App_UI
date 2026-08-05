import 'package:flutter/material.dart';

import '../admin/manage_users_screen.dart';

class SuperAdminUsersScreen extends StatelessWidget {
  const SuperAdminUsersScreen({super.key});

  static const routeName = '/super-admin/users';

  @override
  Widget build(BuildContext context) {
    return const ManageUsersScreen();
  }
}
