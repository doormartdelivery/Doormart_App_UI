import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/delivery_provider.dart';
import 'delivery_login_screen.dart';

class DeliveryProfileScreen extends StatelessWidget {
  const DeliveryProfileScreen({super.key});
  static const routeName = '/delivery/profile';
  @override
  Widget build(BuildContext context) {
    final person = context.watch<DeliveryProvider>().deliveryPerson;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${person?.name ?? ''}'),
            Text('Phone: ${person?.phone ?? ''}'),
            Text('Vehicle number: ${person?.vehicleNumber ?? ''}'),
            Text('Status: ${person?.status ?? 'offline'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await context.read<DeliveryProvider>().logout();
                if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil(DeliveryLoginScreen.routeName, (_) => false);
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
