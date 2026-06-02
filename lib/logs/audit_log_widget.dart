import 'package:flutter/material.dart';

class AuditLogWidget extends StatelessWidget {
  const AuditLogWidget({super.key, required this.action});
  final String action;
  @override
  Widget build(BuildContext context) =>
      ListTile(leading: const Icon(Icons.history), title: Text(action));
}
