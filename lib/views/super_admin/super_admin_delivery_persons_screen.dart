import 'package:flutter/material.dart';

import '../admin/manage_delivery_screen.dart';

class SuperAdminDeliveryPersonsScreen extends StatelessWidget {
  const SuperAdminDeliveryPersonsScreen({super.key});

  static const routeName = '/super-admin/delivery-persons';

  @override
  Widget build(BuildContext context) {
    return const ManageDeliveryScreen();
  }
}
