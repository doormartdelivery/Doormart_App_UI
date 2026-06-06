import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../app_page.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  static const routeName = '/admin/orders';

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late final AnimationController _animationController;
  late Future<List<OrderModel>> _ordersFuture;
  int _sortColumnIndex = 1;
  bool _sortAscending = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _ordersFuture = _loadOrders();
  }

  Future<List<OrderModel>> _loadOrders() {
    return context.read<AppState>().allOrdersForRole(UserRoles.admin);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _moveOrder(OrderModel order, String status) async {
    await context.read<AppState>().updateOrderStatus(order.id, status);
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  void _sortBy(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = columnIndex != 1;
      }
    });
  }

  List<OrderModel> _sortedOrders(List<OrderModel> orders) {
    final sorted = [...orders];
    int compare(OrderModel a, OrderModel b) {
      return switch (_sortColumnIndex) {
        0 => _shortId(a.id).compareTo(_shortId(b.id)),
        1 => a.createdAt.compareTo(b.createdAt),
        2 => _statusLabel(a.status).compareTo(_statusLabel(b.status)),
        3 => a.products.length.compareTo(b.products.length),
        4 => a.total.compareTo(b.total),
        _ => a.createdAt.compareTo(b.createdAt),
      };
    }

    sorted.sort((a, b) {
      final result = compare(a, b);
      return _sortAscending ? result : -result;
    });
    return sorted;
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return orders;

    return orders.where((order) {
      return order.id.toLowerCase().contains(query) ||
          _shortId(order.id).toLowerCase().contains(query) ||
          _statusLabel(order.status).toLowerCase().contains(query) ||
          order.total.toStringAsFixed(0).contains(query) ||
          (order.deliveryPersonName ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Admin Orders',
      actions: [
        IconButton(
          tooltip: 'Refresh orders',
          onPressed: () {
            setState(() {
              _animationController
                ..reset()
                ..forward();
              _ordersFuture = _loadOrders();
            });
          },
          icon: RotationTransition(
            turns: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
      children: [
        FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _OrdersError(message: snapshot.error.toString());
            }
            if (!snapshot.hasData) return const LinearProgressIndicator();
            final allOrders = _sortedOrders(snapshot.data!);
            final orders = _filteredOrders(allOrders);
            if (orders.isEmpty) return const _OrdersEmptyState();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimatedIn(
                  animation: _animationController,
                  index: 0,
                  child: _OrdersHero(orders: allOrders),
                ),
                const SizedBox(height: 14),
                _AnimatedIn(
                  animation: _animationController,
                  index: 1,
                  child: _OrderSearchField(
                    controller: _searchController,
                    onChanged: (value) => setState(() => _query = value),
                    onClear: _query.isEmpty
                        ? null
                        : () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                  ),
                ),
                const SizedBox(height: 14),
                _AnimatedIn(
                  animation: _animationController,
                  index: 2,
                  child: _OrdersTable(
                    orders: orders,
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    onSort: _sortBy,
                    onMove: _moveOrder,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OrderSearchField extends StatelessWidget {
  const _OrderSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search orders by id, status, delivery person, or total',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _OrdersHero extends StatelessWidget {
  const _OrdersHero({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final pending = orders
        .where((order) => order.status == OrderStatus.placed)
        .length;
    final active = orders
        .where(
          (order) =>
              order.status != OrderStatus.delivered &&
              order.status != OrderStatus.cancelled,
        )
        .length;
    final delivered = orders
        .where((order) => order.status == OrderStatus.delivered)
        .length;
    final revenue = orders.fold<double>(0, (sum, order) => sum + order.total);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orders control table',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap any sortable column header to reorder the table.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroMetric(
                  label: 'Total orders',
                  value: '${orders.length}',
                  icon: Icons.shopping_bag,
                  color: const Color(0xFFFFFFFF),
                  index: 0,
                ),
                _HeroMetric(
                  label: 'Pending',
                  value: '$pending',
                  icon: Icons.hourglass_top,
                  color: const Color(0xFFFFEDD5),
                  index: 1,
                ),
                _HeroMetric(
                  label: 'Active',
                  value: '$active',
                  icon: Icons.local_shipping,
                  color: const Color(0xFFDBEAFE),
                  index: 2,
                ),
                _HeroMetric(
                  label: 'Delivered',
                  value: '$delivered',
                  icon: Icons.check_circle,
                  color: const Color(0xFFD1FAE5),
                  index: 3,
                ),
                _HeroMetric(
                  label: 'Revenue',
                  value: 'Rs ${revenue.toStringAsFixed(0)}',
                  icon: Icons.payments,
                  color: const Color(0xFFFCE7F3),
                  index: 4,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + index * 90),
      curve: Curves.easeOutBack,
      builder: (context, progress, child) {
        return Transform.scale(
          scale: 0.92 + progress * 0.08,
          child: Opacity(opacity: progress.clamp(0, 1), child: child),
        );
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({
    required this.orders,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onMove,
  });

  final List<OrderModel> orders;
  final int sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final Future<void> Function(OrderModel order, String status) onMove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDDE7F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Orders table',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: DataTable(
                      sortColumnIndex: sortColumnIndex,
                      sortAscending: sortAscending,
                      headingRowColor:
                          WidgetStateProperty.all(const Color(0xFFECFDF5)),
                      headingTextStyle: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                      dataTextStyle: const TextStyle(
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w600,
                      ),
                      dividerThickness: 0.8,
                      dataRowMinHeight: 68,
                      dataRowMaxHeight: 76,
                      columnSpacing: 26,
                      horizontalMargin: 16,
                      columns: [
                        DataColumn(
                          label: const Text('Order ID'),
                          onSort: (_, __) => onSort(0),
                        ),
                        DataColumn(
                          label: const Text('Date'),
                          onSort: (_, __) => onSort(1),
                        ),
                        DataColumn(
                          label: const Text('Status'),
                          onSort: (_, __) => onSort(2),
                        ),
                        DataColumn(
                          label: const Text('Items'),
                          numeric: true,
                          onSort: (_, __) => onSort(3),
                        ),
                        DataColumn(
                          label: const Text('Total'),
                          numeric: true,
                          onSort: (_, __) => onSort(4),
                        ),
                        const DataColumn(label: Text('Accepted By')),
                        const DataColumn(label: Text('Next Action')),
                      ],
                      rows: orders.asMap().entries.map((entry) {
                        final index = entry.key;
                        final order = entry.value;
                        final action = _nextAction(order.status);
                        return DataRow(
                          color: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return const Color(0xFFEFF6FF);
                            }
                            return index.isEven
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFFF8FAFC);
                          }),
                          cells: [
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-id',
                                index: index,
                                child: Row(
                                  children: [
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const SizedBox(
                                        width: 34,
                                        height: 34,
                                        child: Icon(
                                          Icons.receipt,
                                          color: Color(0xFF475569),
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '#${_shortId(order.id)}',
                                      style: const TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-date',
                                index: index,
                                child: Text(_formatDate(order.createdAt)),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-status-${order.status.name}',
                                index: index,
                                child: _StatusBadge(status: order.status),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-items',
                                index: index,
                                child: Text(
                                  '${order.products.length}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-total',
                                index: index,
                                child: Text(
                                  'Rs ${order.total.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Color(0xFF0F766E),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey:
                                    '${order.id}-delivery-${order.deliveryPersonId}',
                                index: index,
                                child: _DeliveryAcceptedCell(order: order),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey:
                                    '${order.id}-action-${action?.status ?? 'done'}',
                                index: index,
                                child: action == null
                                    ? const _DonePill()
                                    : FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2563EB),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () =>
                                            onMove(order, action.status),
                                        icon: const Icon(
                                          Icons.arrow_forward,
                                          size: 16,
                                        ),
                                        label: Text(action.label),
                                      ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DonePill extends StatelessWidget {
  const _DonePill();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Done',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _DeliveryAcceptedCell extends StatelessWidget {
  const _DeliveryAcceptedCell({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    if (order.deliveryPersonId == null) {
      return Text(
        order.status == OrderStatus.assigned ? 'Waiting' : '-',
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          order.deliveryPersonName ?? 'Accepted',
          style: const TextStyle(
            color: Color(0xFF0F766E),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _OrdersEmptyState extends StatelessWidget {
  const _OrdersEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.receipt_long, color: Color(0xFF2563EB)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No orders available yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final style = _statusStyle(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          _statusLabel(status),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: style.foreground,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _OrdersError extends StatelessWidget {
  const _OrdersError({required this.message});

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

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({
    required this.animation,
    required this.index,
    required this.child,
  });

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(
        (index * 0.12).clamp(0, 0.72),
        1,
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class _TableCellIn extends StatelessWidget {
  const _TableCellIn({
    required this.animationKey,
    required this.index,
    required this.child,
  });

  final String animationKey;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(animationKey),
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index.clamp(0, 8) * 55)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }
}

class _OrderAction {
  const _OrderAction(this.label, this.status);

  final String label;
  final String status;
}

class _BadgeStyle {
  const _BadgeStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

_OrderAction? _nextAction(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => const _OrderAction('Accept', 'accepted'),
    OrderStatus.accepted => const _OrderAction('Pack', 'packed'),
    OrderStatus.packed => const _OrderAction('Assign', 'assigned'),
    OrderStatus.assigned => const _OrderAction('Pickup', 'picked_up'),
    OrderStatus.deliveryAccepted => const _OrderAction('Pickup', 'picked_up'),
    OrderStatus.pickedUp => const _OrderAction('Deliver', 'delivered'),
    OrderStatus.delivered || OrderStatus.cancelled => null,
  };
}

_BadgeStyle _statusStyle(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => const _BadgeStyle(Color(0xFFFFF7ED), Color(0xFFC2410C)),
    OrderStatus.accepted => const _BadgeStyle(Color(0xFFEFF6FF), Color(0xFF1D4ED8)),
    OrderStatus.packed => const _BadgeStyle(Color(0xFFEEF2FF), Color(0xFF4F46E5)),
    OrderStatus.assigned => const _BadgeStyle(Color(0xFFFDF2F8), Color(0xFFBE185D)),
    OrderStatus.deliveryAccepted => const _BadgeStyle(Color(0xFFEAF7EF), Color(0xFF0F766E)),
    OrderStatus.pickedUp => const _BadgeStyle(Color(0xFFECFEFF), Color(0xFF0E7490)),
    OrderStatus.delivered => const _BadgeStyle(Color(0xFFEAF7EF), Color(0xFF0F766E)),
    OrderStatus.cancelled => const _BadgeStyle(Color(0xFFFFF1F2), Color(0xFFBE123C)),
  };
}

String _statusLabel(OrderStatus status) {
  return switch (status) {
    OrderStatus.placed => 'PENDING',
    OrderStatus.accepted => 'ACCEPTED',
    OrderStatus.packed => 'PACKED',
    OrderStatus.assigned => 'ASSIGNED',
    OrderStatus.deliveryAccepted => 'DELIVERY ACCEPTED',
    OrderStatus.pickedUp => 'PICKED UP',
    OrderStatus.delivered => 'DELIVERED',
    OrderStatus.cancelled => 'CANCELLED',
  };
}

String _shortId(String id) {
  if (id.length <= 8) return id;
  return id.substring(id.length - 8).toUpperCase();
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} $hour:$minute';
}

String _columnLabel(int index) {
  return switch (index) {
    0 => 'Order ID',
    1 => 'Date',
    2 => 'Status',
    3 => 'Items',
    4 => 'Total',
    _ => 'Date',
  };
}

Color _flowColor(String label) {
  return switch (label) {
    'NEW' => const Color(0xFFC2410C),
    'CHECK STOCK' => const Color(0xFF9333EA),
    'ACCEPTED' => const Color(0xFF1D4ED8),
    'PACKED' => const Color(0xFF4F46E5),
    'ASSIGNED' => const Color(0xFFBE185D),
    'PICKED UP' => const Color(0xFF0E7490),
    'DELIVERED' => const Color(0xFF0F766E),
    _ => const Color(0xFF475569),
  };
}
