import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../../widgets/order_card.dart';
import '../app_page.dart';

class SuperAdminOrdersScreen extends StatelessWidget {
  const SuperAdminOrdersScreen({super.key});
  static const routeName = '/super-admin/orders';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Super Admin Orders',
      children: [
        FutureBuilder(
          future: context.read<AppState>().allOrdersForRole(
            UserRoles.superAdmin,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final orders = snapshot.data!;
            return Column(
              children: orders
                  .map(
                    (order) =>
                        OrderCard(orderId: order.displayOrderId, status: order.status.name),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
