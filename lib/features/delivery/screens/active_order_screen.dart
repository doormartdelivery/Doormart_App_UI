import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery_order_model.dart';
import '../providers/delivery_provider.dart';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});
  static const routeName = '/delivery/active-order';

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final order = provider.activeOrder;
    if (order == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: Center(child: Text('No active order')),
      );
    }

    final status = _statusLabel(order.status);
    final isCod = order.isCod;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8541A), Color(0xFFFF7A2F)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Active Order',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        _statusPill(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Track and complete the assigned delivery.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.receipt_long_rounded,
                            label: 'Order ID',
                            value: order.displayOrderId,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.storefront_rounded,
                            label: 'Customer',
                            value: order.customerName,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  children: [
                    _DashboardCard(
                      title: 'Order Summary',
                      child: Column(
                        children: [
                          _infoRow('Customer name', order.customerName),
                          _infoRow('Customer phone', order.customerPhone),
                          _infoRow('Customer address', order.customerAddress),
                          _infoRow('Customer area', order.customerArea),
                          _infoRow('Payment method', order.paymentType),
                          if (isCod)
                            _infoRow(
                              'COD amount',
                              '₹${order.codAmount?.toStringAsFixed(2) ?? order.totalAmount.toStringAsFixed(2)}',
                            ),
                          _infoRow('Total amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
                          _infoRow('Created at', _formatDate(order.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardCard(
                      title: 'Ordered Items',
                      child: order.items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No item details available'),
                            )
                          : Column(
                              children: order.items
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _OrderedItemTile(item: item),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardCard(
                      title: 'Delivery Actions',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF171923),
                              const Color(0xFF1F2937),
                              const Color(0xFF0F172A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8541A).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0x66E8541A)),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Color(0xFFFF8A3D),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Control Center',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'Fast actions for delivery execution',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.68),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ActionTile(
                              icon: Icons.map_outlined,
                              title: 'Open Google Maps',
                              subtitle: 'Navigate to customer address',
                              accent: const Color(0xFFFF8A3D),
                              onTap: () => _openMap(order.customerAddress),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.call_outlined,
                              title: 'Call customer',
                              subtitle: 'Connect instantly with the customer',
                              accent: const Color(0xFFFFA142),
                              onTap: () => _call(order.customerPhone),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Mark Picked Up',
                              subtitle: 'Update when package leaves the shed',
                              accent: const Color(0xFFFFB366),
                              onTap: provider.markPickedUp,
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.local_shipping_rounded,
                              title: 'Mark Delivered',
                              subtitle: 'Complete the delivery flow',
                              accent: const Color(0xFFE8541A),
                              isPrimary: true,
                              onTap: () async {
                                final message = await provider.markDelivered('');
                                if (!context.mounted) return;
                                if (message != null && message.isNotEmpty) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(content: Text(message)));
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(DeliveryOrderStatus status) {
    return switch (status) {
      DeliveryOrderStatus.waitingForAccept => 'Waiting',
      DeliveryOrderStatus.accepted => 'Accepted',
      DeliveryOrderStatus.pickedUp => 'Picked up',
      DeliveryOrderStatus.outForDelivery => 'Out for delivery',
      DeliveryOrderStatus.delivered => 'Delivered',
      DeliveryOrderStatus.rejected => 'Rejected',
    };
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  Future<void> _openMap(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF0EB),
          borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD2C0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8541A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrderedItemTile extends StatelessWidget {
  const _OrderedItemTile({required this.item});

  final DeliveryOrderItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final hasPrice = item.unitPrice > 0;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFFFF0EB),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFE8541A),
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFE8541A),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasPrice
                        ? 'Qty: ${item.quantity}  •  ₹${item.unitPrice.toStringAsFixed(2)} each'
                        : 'Qty: ${item.quantity}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                        label: 'Item total',
                        value: hasPrice ? '₹${item.lineTotal.toStringAsFixed(2)}' : '—',
                      ),
                      const SizedBox(width: 10),
                      _Badge(
                        label: 'Ordered',
                        value: '${item.quantity}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8541A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [
                      accent.withValues(alpha: 0.95),
                      const Color(0xFFFF7A2F),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: isPrimary ? 0.34 : 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
