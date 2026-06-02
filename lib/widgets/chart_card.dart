import 'package:flutter/material.dart';

import 'animated_chart.dart';

class ChartCard extends StatelessWidget {
  const ChartCard({super.key, required this.title, required this.values});
  final String title;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title),
            const SizedBox(height: 12),
            SizedBox(height: 120, child: AnimatedChart(values: values)),
          ],
        ),
      ),
    );
  }
}
