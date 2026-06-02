import 'package:flutter/material.dart';

import '../../providers/delivery_provider.dart';
import '../app_page.dart';

class ManageDeliveryScreen extends StatelessWidget {
  const ManageDeliveryScreen({super.key});

  static const routeName = '/admin/delivery';

  @override
  Widget build(BuildContext context) {
    final people = DeliveryProvider().people;
    return AppPage(
      title: 'Manage delivery',
      children: people
          .map(
            (person) => SwitchListTile(
              value: person.active,
              onChanged: (_) {},
              title: Text(person.name),
              subtitle: Text('${person.completedOrders} completed orders'),
            ),
          )
          .toList(),
    );
  }
}
