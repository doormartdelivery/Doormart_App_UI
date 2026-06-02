import 'package:flutter/material.dart';

import '../app_page.dart';

class AuditLogsScreen extends StatelessWidget {
  const AuditLogsScreen({super.key});

  static const routeName = '/admin/audit-logs';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Audit logs',
      children: [
        ListTile(
          leading: Icon(Icons.history),
          title: Text('Product price updated'),
          subtitle: Text('admin changed A2 Milk from Rs 70 to Rs 72'),
        ),
        ListTile(
          leading: Icon(Icons.lock),
          title: Text('Role access checked'),
          subtitle: Text('super_admin dashboard blocked for admin role'),
        ),
      ],
    );
  }
}
