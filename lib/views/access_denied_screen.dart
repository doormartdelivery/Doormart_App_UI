import 'package:flutter/material.dart';

import 'app_page.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  static const routeName = '/403';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: '403 Forbidden',
      children: [
        Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.lock_outline_rounded, size: 42),
                SizedBox(height: 12),
                Text(
                  'You do not have permission to access this page.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
