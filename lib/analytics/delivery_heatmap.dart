import 'package:flutter/material.dart';

class DeliveryHeatmap extends StatelessWidget {
  const DeliveryHeatmap({super.key});
  @override
  Widget build(BuildContext context) => const Card(
    child: SizedBox(
      height: 180,
      child: Center(child: Text('Delivery zone heatmap')),
    ),
  );
}
