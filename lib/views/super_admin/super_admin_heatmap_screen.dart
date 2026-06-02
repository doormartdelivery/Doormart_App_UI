import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../app_page.dart';

class SuperAdminHeatmapScreen extends StatelessWidget {
  const SuperAdminHeatmapScreen({super.key});
  static const routeName = '/super-admin/heatmap';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Delivery Heatmap',
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: context.read<AppState>().superAdminAnalytics(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final zones = snapshot.data!['zoneHeatmap'] as List<dynamic>? ?? [];
            return Column(
              children: zones.map((zone) {
                final item = zone as Map<String, dynamic>;
                final orders = item['orders'] as int? ?? 0;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.map),
                    title: Text(item['zone'] as String? ?? 'Zone'),
                    subtitle: LinearProgressIndicator(value: orders / 50),
                    trailing: Text('$orders'),
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
