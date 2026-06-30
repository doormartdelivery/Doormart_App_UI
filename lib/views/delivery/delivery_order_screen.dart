import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/order_status_widget.dart';
import '../../widgets/toast_widget.dart';
import '../app_page.dart';

class DeliveryOrderScreen extends StatefulWidget {
  const DeliveryOrderScreen({super.key});

  static const routeName = '/delivery/order';

  @override
  State<DeliveryOrderScreen> createState() => _DeliveryOrderScreenState();
}

class _DeliveryOrderScreenState extends State<DeliveryOrderScreen> {
  late Future<List<OrderModel>> _ordersFuture;
  final Set<String> _updatingOrders = {};
  _OrderFilter _filter = _OrderFilter.all;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<OrderModel>> _loadOrders() {
    return context.read<AppState>().availableDeliveryOrders();
  }

  Future<void> _runOrderAction({
    required OrderModel order,
    required Future<OrderModel> Function(AppState appState, String orderId)
    action,
    required String successMessage,
  }) async {
    setState(() => _updatingOrders.add(order.id));
    try {
      final updated = await action(context.read<AppState>(), order.id);
      if (!mounted) return;
      if (successMessage == 'marked as delivered') {
        showToast(context, 'Order #${_shortId(updated.id)} delivered successfully');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #${_shortId(updated.id)} $successMessage'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingOrders.remove(order.id);
        _ordersFuture = _loadOrders();
      });
    }
  }

  Future<void> _acceptOrder(OrderModel order) {
    return _runOrderAction(
      order: order,
      action: (appState, orderId) => appState.acceptDeliveryOrder(orderId),
      successMessage: 'accepted',
    );
  }

  Future<void> _pickupOrder(OrderModel order) {
    return _runOrderAction(
      order: order,
      action: (appState, orderId) => appState.pickupDeliveryOrder(orderId),
      successMessage: 'marked as picked up',
    );
  }

  Future<void> _deliverOrder(OrderModel order) {
    return _runOrderAction(
      order: order,
      action: (appState, orderId) => appState.deliverDeliveryOrder(orderId),
      successMessage: 'marked as delivered',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Delivery order',
      actions: [
        IconButton(
          tooltip: 'Refresh orders',
          onPressed: () => setState(() => _ordersFuture = _loadOrders()),
          icon: const Icon(Icons.refresh),
        ),
      ],
      children: [
        FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _DeliveryOrderError(message: snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final orders = snapshot.data!;
            final visibleOrders = _filteredOrders(orders, _filter);
            if (orders.isEmpty) {
              return const _NoDeliveryOrders();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DeliveryOrdersHeader(
                  count: orders.length,
                  activeCount: orders.where(_isInProgress).length,
                  totalValue: orders.fold<double>(
                    0,
                    (sum, order) => sum + order.total,
                  ),
                ),
                const SizedBox(height: 14),
                _OrderFilterBar(
                  selected: _filter,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
                const SizedBox(height: 14),
                if (visibleOrders.isEmpty)
                  const _FilteredEmptyOrders()
                else
                  ...visibleOrders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DeliveryOrderCard(
                        order: order,
                        updating: _updatingOrders.contains(order.id),
                        onAccept: () => _acceptOrder(order),
                        onPickup: () => _pickupOrder(order),
                        onDelivered: () => _deliverOrder(order),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        const OrderStatusWidget(activeStep: 3),
      ],
    );
  }
}

class _DeliveryOrdersHeader extends StatelessWidget {
  const _DeliveryOrdersHeader({
    required this.count,
    required this.activeCount,
    required this.totalValue,
  });

  final int count;
  final int activeCount;
  final double totalValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10231F),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10231F).withValues(alpha: .18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _OrderHeaderPainter())),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8FF72).withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE8FF72).withValues(alpha: .22),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFFE8FF72),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$count orders ready',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Review, pickup, and complete deliveries',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: .72),
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        label: 'Active',
                        value: '$activeCount',
                        icon: Icons.route_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderStat(
                        label: 'Value',
                        value: 'Rs ${totalValue.toStringAsFixed(0)}',
                        icon: Icons.payments_outlined,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE8FF72), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: .66),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderFilterBar extends StatelessWidget {
  const _OrderFilterBar({required this.selected, required this.onChanged});

  final _OrderFilter selected;
  final ValueChanged<_OrderFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFECE7D8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: _OrderFilter.values.map((filter) {
          final active = filter == selected;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => onChanged(filter),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .06),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _filterLabel(filter),
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF16231F)
                        : const Color(0xFF66706B),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrderHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1.2;
    final accentPaint = Paint()
      ..color = const Color(0xFFE8FF72).withValues(alpha: .25)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var y = 24.0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), linePaint);
    }

    final path = Path()
      ..moveTo(size.width * .45, size.height + 8)
      ..cubicTo(
        size.width * .58,
        size.height * .48,
        size.width * .74,
        size.height * .3,
        size.width + 16,
        28,
      );
    canvas.drawPath(path, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FilteredEmptyOrders extends StatelessWidget {
  const _FilteredEmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2DED0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.filter_alt_off_outlined, color: Color(0xFF66706B)),
          SizedBox(width: 10),
          Expanded(child: Text('No orders match this filter.')),
        ],
      ),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  const _DeliveryOrderCard({
    required this.order,
    required this.updating,
    required this.onAccept,
    required this.onPickup,
    required this.onDelivered,
  });

  final OrderModel order;
  final bool updating;
  final VoidCallback onAccept;
  final VoidCallback onPickup;
  final VoidCallback onDelivered;

  @override
  Widget build(BuildContext context) {
    final alreadyAccepted = order.deliveryPersonId != null;
    final action = _deliveryActionFor(order);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2DED0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _actionColor(action).withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForAction(action),
                    color: _actionColor(action),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.displayOrderId}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF16231F),
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${order.products.length} items | Rs ${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                _DeliveryStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF66706B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.address.isEmpty
                        ? 'Pickup address pending'
                        : order.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF66706B),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _statusProgress(order.status),
                minHeight: 5,
                backgroundColor: const Color(0xFFECE7D8),
                color: _actionColor(action),
              ),
            ),
            if (alreadyAccepted) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.verified, size: 16, color: Color(0xFF0F766E)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Accepted by ${order.deliveryPersonName ?? 'you'}',
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _DeliveryActionButton(
                action: action,
                updating: updating,
                onAccept: onAccept,
                onPickup: onPickup,
                onDelivered: onDelivered,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryStatusBadge extends StatelessWidget {
  const _DeliveryStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);

    return Align(
      alignment: Alignment.centerLeft,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          child: Text(
            _statusLabel(status),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: style.foreground,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
      ),
    );
  }
}

class _DeliveryActionButton extends StatelessWidget {
  const _DeliveryActionButton({
    required this.action,
    required this.updating,
    required this.onAccept,
    required this.onPickup,
    required this.onDelivered,
  });

  final _DeliveryAction action;
  final bool updating;
  final VoidCallback onAccept;
  final VoidCallback onPickup;
  final VoidCallback onDelivered;

  @override
  Widget build(BuildContext context) {
    final enabled = !updating && action != _DeliveryAction.done;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: _actionColor(action),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2DED0),
        disabledForegroundColor: const Color(0xFF66706B),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: enabled ? _callbackForAction(action) : null,
      icon: updating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(_iconForAction(action), size: 18),
      label: Text(_labelForAction(action)),
    );
  }

  VoidCallback _callbackForAction(_DeliveryAction action) {
    return switch (action) {
      _DeliveryAction.accept => onAccept,
      _DeliveryAction.pickup => onPickup,
      _DeliveryAction.deliver => onDelivered,
      _DeliveryAction.done => () {},
    };
  }
}

class _NoDeliveryOrders extends StatelessWidget {
  const _NoDeliveryOrders();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2DED0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_clock, color: Color(0xFF173B33)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No assigned orders',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 3),
                Text('New delivery notifications will appear here.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOrderError extends StatelessWidget {
  const _DeliveryOrderError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFBE123C),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

String _shortId(String id) {
  if (id.length <= 8) return id;
  return id.substring(id.length - 8).toUpperCase();
}

enum _DeliveryAction { accept, pickup, deliver, done }

enum _OrderFilter { all, newOrders, active }

class _BadgeStyle {
  const _BadgeStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

_DeliveryAction _deliveryActionFor(OrderModel order) {
  return switch (order.status) {
    OrderStatus.deliveryAccepted => _DeliveryAction.pickup,
    OrderStatus.pickedUp => _DeliveryAction.deliver,
    OrderStatus.delivered => _DeliveryAction.done,
    _ => _DeliveryAction.accept,
  };
}

IconData _iconForAction(_DeliveryAction action) {
  return switch (action) {
    _DeliveryAction.accept => Icons.check_circle,
    _DeliveryAction.pickup => Icons.inventory_2,
    _DeliveryAction.deliver => Icons.task_alt,
    _DeliveryAction.done => Icons.done_all,
  };
}

String _labelForAction(_DeliveryAction action) {
  return switch (action) {
    _DeliveryAction.accept => 'Accept',
    _DeliveryAction.pickup => 'Picked up',
    _DeliveryAction.deliver => 'Delivered',
    _DeliveryAction.done => 'Done',
  };
}

Color _actionColor(_DeliveryAction action) {
  return switch (action) {
    _DeliveryAction.accept => const Color(0xFF173B33),
    _DeliveryAction.pickup => const Color(0xFFC78417),
    _DeliveryAction.deliver => const Color(0xFF2556A4),
    _DeliveryAction.done => const Color(0xFF0F766E),
  };
}

_BadgeStyle _statusStyle(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => const _BadgeStyle(
      Color(0xFFFFF7ED),
      Color(0xFFC2410C),
    ),
    OrderStatus.accepted => const _BadgeStyle(
      Color(0xFFEFF6FF),
      Color(0xFF1D4ED8),
    ),
    OrderStatus.packed => const _BadgeStyle(
      Color(0xFFEEF2FF),
      Color(0xFF4F46E5),
    ),
    OrderStatus.assigned => const _BadgeStyle(
      Color(0xFFFDF2F8),
      Color(0xFFBE185D),
    ),
    OrderStatus.deliveryAccepted => const _BadgeStyle(
      Color(0xFFEAF7EF),
      Color(0xFF0F766E),
    ),
    OrderStatus.pickedUp => const _BadgeStyle(
      Color(0xFFECFEFF),
      Color(0xFF0E7490),
    ),
    OrderStatus.delivered => const _BadgeStyle(
      Color(0xFFEAF7EF),
      Color(0xFF0F766E),
    ),
    OrderStatus.cancelled => const _BadgeStyle(
      Color(0xFFFFF1F2),
      Color(0xFFBE123C),
    ),
  };
}

String _statusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => 'PENDING',
    OrderStatus.accepted => 'ACCEPTED',
    OrderStatus.packed => 'PACKED',
    OrderStatus.assigned => 'READY TO ACCEPT',
    OrderStatus.deliveryAccepted => 'ACCEPTED',
    OrderStatus.pickedUp => 'PICKED UP',
    OrderStatus.delivered => 'DELIVERED',
    OrderStatus.cancelled => 'CANCELLED',
  };
}

List<OrderModel> _filteredOrders(List<OrderModel> orders, _OrderFilter filter) {
  return switch (filter) {
    _OrderFilter.all => orders,
    _OrderFilter.newOrders => orders.where((order) {
        return order.status != OrderStatus.deliveryAccepted &&
            order.status != OrderStatus.pickedUp &&
            order.status != OrderStatus.delivered;
      }).toList(),
    _OrderFilter.active => orders.where(_isInProgress).toList(),
  };
}

bool _isInProgress(OrderModel order) {
  return order.status == OrderStatus.deliveryAccepted ||
      order.status == OrderStatus.pickedUp;
}

String _filterLabel(_OrderFilter filter) {
  return switch (filter) {
    _OrderFilter.all => 'All',
    _OrderFilter.newOrders => 'New',
    _OrderFilter.active => 'Active',
  };
}

double _statusProgress(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => .18,
    OrderStatus.accepted => .32,
    OrderStatus.packed => .48,
    OrderStatus.assigned => .58,
    OrderStatus.deliveryAccepted => .68,
    OrderStatus.pickedUp => .84,
    OrderStatus.delivered => 1,
    OrderStatus.cancelled => .08,
  };
}
