import 'package:flutter/material.dart';

class DeliveryStatusBadge extends StatelessWidget {
  const DeliveryStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final online = status.toLowerCase() == 'online';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: online ? Colors.green.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        online ? 'Online' : 'Offline',
        style: TextStyle(
          color: online ? Colors.green.shade800 : Colors.grey.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
