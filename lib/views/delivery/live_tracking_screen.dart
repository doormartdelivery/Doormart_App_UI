import 'package:flutter/material.dart';

import '../app_page.dart';

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  static const routeName = '/delivery/live-tracking';

  @override
  Widget build(BuildContext context) {
    return const AppPage(
      title: 'Live tracking',
      children: [
        Card(
          child: SizedBox(
            height: 260,
            child: Center(
              child: Text('Google Maps Flutter integration placeholder'),
            ),
          ),
        ),
        ListTile(
          leading: Icon(Icons.sensors),
          title: Text('Location stream'),
          subtitle: Text(
            'Updates are emitted to the backend through Socket.IO',
          ),
        ),
      ],
    );
  }
}
