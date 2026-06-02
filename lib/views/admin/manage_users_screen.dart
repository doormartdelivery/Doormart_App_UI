import 'package:flutter/material.dart';

import '../app_page.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  static const routeName = '/admin/users';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Manage users',
      children: [
        ListTile(
          leading: Icon(Icons.person),
          title: Text('Demo User'),
          subtitle: Text('user'),
        ),
        ListTile(
          leading: Icon(Icons.admin_panel_settings),
          title: Text('Store Admin'),
          subtitle: Text('admin'),
        ),
      ],
    );
  }
}
