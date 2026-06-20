import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../models/product_model.dart';
import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});
  static const routeName = '/my-orders';

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) return;
        context.read<AppState>().loadOrders();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'My Orders',
      bottomNavIndex: 1,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 26,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ),
      children: [
        Consumer<AppState>(
          builder: (context, state, _) {
            final orders = state.orders;
            if (state.loading && orders.isEmpty) {
              return const LinearProgressIndicator();
            }
            if (orders.isEmpty) return const Text('No orders yet');

            final currentOrders = _currentOrdersFrom(orders);
            final previousOrders = orders.where((order) => order.status == OrderStatus.delivered).toList();
            final totalOrders = orders.length;
            final activeOrders = orders.where((order) => _isActive(order.status)).length;
            final deliveredOrders = orders.where((order) => order.status == OrderStatus.delivered).length;
            final totalSpent = orders.fold<double>(0, (sum, order) => sum + order.total);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryPanel(
                  totalOrders: totalOrders,
                  activeOrders: activeOrders,
                  deliveredOrders: deliveredOrders,
                  totalSpent: totalSpent,
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Column(
                    key: ValueKey(currentOrders.length),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(title: 'Current Orders', count: currentOrders.length),
                      const SizedBox(height: 12),
                      if (currentOrders.isEmpty)
                        const Text('No active orders right now')
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final columns = width >= 1100
                                ? 2
                                : width >= 700
                                    ? 2
                                    : 1;
                            final cardWidth = columns == 1 ? width : (width - 14) / 2;
                            return Wrap(
                              spacing: 14,
                              runSpacing: 14,
                              children: currentOrders
                                  .map(
                                    (order) => SizedBox(
                                      width: cardWidth,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(milliseconds: 220),
                                        child: _CurrentOrderCard(
                                          key: ValueKey('current-${order.id}-${order.status.name}'),
                                          order: order,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                _SectionHeader(title: 'Previous Orders', count: previousOrders.length),
                const SizedBox(height: 12),
                if (previousOrders.isEmpty)
                  const Text('No previous orders yet')
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final columns = width >= 1100
                          ? 2
                          : width >= 700
                              ? 2
                              : 1;
                      final cardWidth = columns == 1 ? width : (width - 14) / 2;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: previousOrders
                            .map(
                              (order) => SizedBox(
                                width: cardWidth,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: _PreviousOrderCard(
                                    key: ValueKey('previous-${order.id}-${order.status.name}'),
                                    order: order,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

bool _isActive(OrderStatus status) {
  return status == OrderStatus.accepted ||
      status == OrderStatus.packed ||
      status == OrderStatus.assigned ||
      status == OrderStatus.deliveryAccepted ||
      status == OrderStatus.pickedUp;
}

List<OrderModel> _currentOrdersFrom(List<OrderModel> orders) {
  return orders
      .where((order) => order.status != OrderStatus.delivered && order.status != OrderStatus.cancelled)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

class _CurrentOrderCard extends StatelessWidget {
  const _CurrentOrderCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final status = order.status.name.toUpperCase();
    final timeline = _timelineFor(order.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                                          'ORDER #${order.displayOrderId}',
                    style: const TextStyle(
                      color: Color(0xFFE8541A),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusPill(label: status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _formatDate(order.createdAt),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _info('Address', order.address.isEmpty ? '—' : order.address),
            if (order.deliveryPersonName != null)
              _info('Delivery partner', order.deliveryPersonName!),
            _info('Total', '₹${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD5C4)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Delivery OTP',
                    style: TextStyle(
                      color: Color(0xFFE8541A),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    order.deliveryOtpDisplay,
                    style: const TextStyle(
                      color: Color(0xFFE8541A),
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Status Timeline',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            _StatusTimeline(steps: timeline),
            const SizedBox(height: 14),
            const Text(
              'Ordered Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            if (order.products.isEmpty)
              const Text(
                'No item details available',
                style: TextStyle(color: Color(0xFF6B7280)),
              )
            else
              Column(
                children: order.products
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ItemRow(item: item),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE8541A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'TRACK ORDER',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
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
}

class _PreviousOrderCard extends StatelessWidget {
  const _PreviousOrderCard({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final status = order.status.name.toUpperCase();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'ORDER #${order.displayOrderId}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                _StatusPill(label: status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _formatDate(order.createdAt),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _info('Address', order.address.isEmpty ? '—' : order.address),
            if (order.deliveryPersonName != null)
              _info('Delivery partner', order.deliveryPersonName!),
            if ((order.deliveryOtp ?? '').isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD5C4)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Delivery OTP',
                      style: TextStyle(
                        color: Color(0xFFE8541A),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      order.deliveryOtp!,
                      style: const TextStyle(
                        color: Color(0xFFE8541A),
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
            _info('Total', '₹${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 14),
            const Text(
              'Ordered Items',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            if (order.products.isEmpty)
              const Text(
                'No item details available',
                style: TextStyle(color: Color(0xFF6B7280)),
              )
            else
              Column(
                children: order.products
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ItemRow(item: item),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
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

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
    required this.totalSpent,
  });

  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8541A), Color(0xFFFF7A2F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8541A).withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'All your recent order activity at a glance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.84),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SummaryTile(label: 'Total', value: '$totalOrders')),
              const SizedBox(width: 10),
              Expanded(child: _SummaryTile(label: 'Active', value: '$activeOrders')),
              const SizedBox(width: 10),
              Expanded(child: _SummaryTile(label: 'Delivered', value: '$deliveredOrders')),
            ],
          ),
          const SizedBox(height: 12),
          _SummaryTile(
            label: 'Total Spent',
            value: '₹${totalSpent.toStringAsFixed(2)}',
            wide: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, this.wide = false});

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.steps});

  final List<_TimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isLast = index == steps.length - 1;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: step.done ? const Color(0xFFE8541A) : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 34,
                    color: step.done ? const Color(0xFFE8541A) : const Color(0xFFE5E7EB),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              color: step.done ? const Color(0xFFE8541A) : const Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (step.isLive)
                          const _LiveBadge(),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0EB),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFFE8541A),
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.done,
    this.isLive = false,
  });
  final String title;
  final String subtitle;
  final bool done;
  final bool isLive;
}

List<_TimelineStep> _timelineFor(OrderStatus status) {
  final placed = _TimelineStep(title: 'Order Placed', subtitle: 'Received by system', done: true);
  final processing = _TimelineStep(
    title: 'Processing',
    subtitle: 'Order is being prepared',
    done: status == OrderStatus.accepted ||
        status == OrderStatus.packed ||
        status == OrderStatus.assigned ||
        status == OrderStatus.deliveryAccepted ||
        status == OrderStatus.pickedUp ||
        status == OrderStatus.delivered,
    isLive: status != OrderStatus.delivered && status != OrderStatus.cancelled,
  );
  final inTransit = _TimelineStep(
    title: 'In Transit',
    subtitle: 'Delivery is on the way',
    done: status == OrderStatus.pickedUp ||
        status == OrderStatus.deliveryAccepted ||
        status == OrderStatus.delivered,
  );
  final delivered = _TimelineStep(
    title: 'Delivered',
    subtitle: 'Order completed',
    done: status == OrderStatus.delivered,
  );
  return [placed, processing, inTransit, delivered];
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.95 + (_controller.value * 0.08);
        final opacity = 0.62 + (_controller.value * 0.38);
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8541A).withValues(alpha: opacity),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8541A).withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ProductModel item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = NetworkImageUrl.normalize(item.imageUrl);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9EEF5)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 54,
              height: 54,
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.category} • ${item.unit}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '₹${item.price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFFE8541A),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8541A),
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}
