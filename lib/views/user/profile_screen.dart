import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../app_page.dart';
import 'address_screen.dart';
import 'my_orders_screen.dart';
import 'notification_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'signup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return AppPage(
      title: 'Profile',
      children: [
        if (state.signedIn) ...[
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(state.user?.name ?? 'Doormart customer'),
              subtitle: Text(
                [
                  if ((state.user?.email ?? '').isNotEmpty) state.user!.email!,
                  state.user?.phone ?? '9999999999',
                ].join(' • '),
              ),
              trailing: FilledButton.tonal(
                onPressed: () => context.read<AppState>().refreshProfile(),
                child: const Text('Refresh'),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    child: Icon(Icons.person, size: 30),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You are not signed in',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to view your profile, orders, addresses, and notifications.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, LoginScreen.routeName),
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            SignupScreen.routeName,
                          ),
                          child: const Text('Register'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
