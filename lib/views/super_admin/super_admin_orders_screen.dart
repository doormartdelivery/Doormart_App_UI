import 'package:flutter/material.dart';

import '../admin/admin_orders_screen.dart';

class SuperAdminOrdersScreen extends StatelessWidget {
  const SuperAdminOrdersScreen({super.key});

  static const routeName = '/super-admin/orders';

  @override
  Widget build(BuildContext context) => const AdminOrdersScreen();
}
