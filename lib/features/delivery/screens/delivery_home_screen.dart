import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/delivery_provider.dart';
import '../widgets/active_order_card.dart';
import '../widgets/delivery_status_badge.dart';
import '../widgets/new_order_request_card.dart';
import 'active_order_screen.dart';
import 'delivery_history_screen.dart';
import 'delivery_profile_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});
  static const routeName = '/delivery';
  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DeliveryProvider>().loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final person = provider.deliveryPerson;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          if (person != null) Padding(padding: const EdgeInsets.only(right: 12), child: DeliveryStatusBadge(status: person.status)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: provider.online,
            onChanged: (value) => value ? provider.goOnline() : provider.goOffline(),
            title: const Text('Online / Offline'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _MetricCard(title: 'Today completed', value: '${person?.completedOrders ?? 0}')),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(title: 'Today earnings', value: '₹${person?.todayEarnings.toStringAsFixed(2) ?? '0.00'}')),
            ],
          ),
          const SizedBox(height: 16),
          if (provider.activeOrder != null) ...[
            const Text('Active Order'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamed(ActiveOrderScreen.routeName),
              child: ActiveOrderCard(order: provider.activeOrder!),
            ),
            const SizedBox(height: 16),
          ],
          const Text('New Requests'),
          const SizedBox(height: 8),
          ...provider.pendingRequests.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NewOrderRequestCard(
                order: order,
                onExpired: () => provider.removePendingOrder(order.id),
                onAccept: () => provider.acceptOrder(order),
                onReject: () => provider.rejectOrder(order),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _ShortcutCard(
                  title: 'History',
                  icon: Icons.history_rounded,
                  onTap: () => Navigator.of(context).pushNamed(DeliveryHistoryScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutCard(
                  title: 'Profile',
                  icon: Icons.person_rounded,
                  onTap: () => Navigator.of(context).pushNamed(DeliveryProfileScreen.routeName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});
  final String title;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), const SizedBox(height: 8), Text(value, style: Theme.of(context).textTheme.headlineSmall)]),
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [Icon(icon, size: 28), const SizedBox(height: 8), Text(title)],
          ),
        ),
      ),
    );
  }
}
