import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});
  static const routeName = '/notifications';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Notifications',
      children: [
        FutureBuilder<List<dynamic>>(
          future: context.read<AppState>().notificationsForRole(UserRoles.user),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            if (snapshot.data!.isEmpty) return const Text('No notifications');
            return Column(
              children: snapshot.data!.map((item) {
                final notification = item as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.notifications),
                    title: Text(notification['title'] as String? ?? ''),
                    subtitle: Text(notification['body'] as String? ?? ''),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
