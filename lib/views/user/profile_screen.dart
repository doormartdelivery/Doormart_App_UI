import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../app_page.dart';
import 'address_screen.dart';
import 'my_orders_screen.dart';
import 'notification_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppPage(
      title: 'Profile',
      children: [
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(state.user?.name ?? 'Doormart customer'),
            subtitle: Text(state.user?.phone ?? '9999999999'),
            trailing: FilledButton.tonal(
              onPressed: () => state.loginDemo(),
              child: const Text('Demo login'),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long),
          title: const Text('My orders'),
          onTap: () => Navigator.pushNamed(context, MyOrdersScreen.routeName),
        ),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: const Text('Addresses'),
          onTap: () => Navigator.pushNamed(context, AddressScreen.routeName),
        ),
        ListTile(
          leading: const Icon(Icons.notifications),
          title: const Text('Notifications'),
          onTap: () =>
              Navigator.pushNamed(context, NotificationScreen.routeName),
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () => Navigator.pushNamed(context, SettingsScreen.routeName),
        ),
      ],
    );
  }
}
