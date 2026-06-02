import 'package:flutter/material.dart';

import '../app_page.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const routeName = '/super-admin/reports';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Reports',
      children: [
        ListTile(
          leading: Icon(Icons.file_download),
          title: Text('Daily, weekly, monthly reports'),
          subtitle: Text('Backend utilities export CSV and PDF'),
        ),
      ],
    );
  }
}
