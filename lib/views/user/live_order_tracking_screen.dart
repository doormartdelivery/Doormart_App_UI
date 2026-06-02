import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class LiveOrderTrackingScreen extends StatelessWidget {
  const LiveOrderTrackingScreen({super.key});
  static const routeName = '/live-order-tracking';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Live Tracking',
    icon: Icons.map,
    description:
        'Google Map markers, delivery contact, ETA, and status timeline.',
  );
}
