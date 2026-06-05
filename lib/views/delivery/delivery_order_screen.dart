import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/order_status_widget.dart';
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
            if (orders.isEmpty) {
              return const _NoDeliveryOrders();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DeliveryOrdersHeader(count: orders.length),
                const SizedBox(height: 12),
                ...orders.map(
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
  const _DeliveryOrdersHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12372A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count assigned orders available',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 46,
                height: 46,
                child: Icon(Icons.local_shipping, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${_shortId(order.id)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${order.products.length} items | Rs ${order.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DeliveryStatusBadge(status: order.status),
                  if (alreadyAccepted) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Accepted by ${order.deliveryPersonName ?? 'you'}',
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _DeliveryActionButton(
              action: action,
              updating: updating,
              onAccept: onAccept,
              onPickup: onPickup,
              onDelivered: onDelivered,
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
    return const ListTile(
      leading: Icon(Icons.lock_clock),
      title: Text('No assigned orders'),
      subtitle: Text('New delivery notifications will appear here.'),
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
