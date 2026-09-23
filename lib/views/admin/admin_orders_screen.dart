import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/order_model.dart';
import '../../models/vendor_model.dart';
import '../../providers/app_state.dart';
import 'admin_logout_confirm.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notifications_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_banners_screen.dart';
import 'stock_screen.dart';
import 'admin_sidebar_drawer.dart';

const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);

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
  int _sortColumnIndex = 6;
  bool _sortAscending = false;
  String _query = '';
  String? _vendorFilter;
  Map<String, VendorModel> _vendorLookup = {};
  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapOrders();
    });
  }

  Future<void> _bootstrapOrders() async {
    final state = context.read<AppState>();
    var shouldStartPolling = false;
    try {
      if (state.user?.role == UserRoles.vendor) {
        await state.refreshProfile();
      }
      await state.loadAdminOrders();
      if (state.user?.role == UserRoles.superAdmin) {
        await _loadVendorLookup();
      }
      shouldStartPolling = true;
    } finally {
      if (!mounted) return;
      setState(() => _bootstrapping = false);
      if (shouldStartPolling) {
        _startPolling();
      }
    }
  }

  void _startPolling() {
    Future.doWhile(() async {
      if (!mounted) return false;
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      final state = context.read<AppState>();
      await state.loadAdminOrders();
      if (state.user?.role == UserRoles.superAdmin) {
        await _loadVendorLookup();
      }
      return true;
    });
  }

  Future<void> _loadVendorLookup() async {
    final state = context.read<AppState>();
    if (state.user?.role != UserRoles.superAdmin) {
      if (mounted) {
        setState(() => _vendorLookup = {});
      }
      return;
    }
    try {
      final vendors = await state.adminVendors();
      if (!mounted) return;
      setState(() {
        _vendorLookup = {
          for (final vendor in vendors) vendor.vendorId: vendor,
          for (final vendor in vendors) vendor.id: vendor,
        };
      });
    } catch (error) {
      debugPrint('Vendor lookup skipped: $error');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _moveOrder(OrderModel order, String status) async {
    await context.read<AppState>().updateOrderStatus(order.id, status);
    await context.read<AppState>().loadAdminOrders();
  }

  Future<void> _refreshOrders() async {
    final state = context.read<AppState>();
    await state.loadAdminOrders();
    if (state.user?.role == UserRoles.superAdmin) {
      await _loadVendorLookup();
    }
    if (!mounted) return;
    setState(() {
      _animationController
        ..reset()
        ..forward();
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
        1 => (a.acceptedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          b.acceptedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
        ),
        2 =>
          (a.deliveredAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            b.deliveredAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
        3 => _statusLabel(a.status).compareTo(_statusLabel(b.status)),
        4 => a.products.length.compareTo(b.products.length),
        5 => a.total.compareTo(b.total),
        6 => a.createdAt.compareTo(b.createdAt),
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
      final vendor = _vendorLookup[order.vendorId];
      final vendorLocation = _vendorLocationLabel(vendor);
      return order.id.toLowerCase().contains(query) ||
          order.displayOrderId.toLowerCase().contains(query) ||
          _shortId(order.id).toLowerCase().contains(query) ||
          _statusLabel(order.status).toLowerCase().contains(query) ||
          order.total.toStringAsFixed(0).contains(query) ||
          (order.deliveryPersonName ?? '').toLowerCase().contains(query) ||
          (order.deliveryPersonPhone ?? '').toLowerCase().contains(query) ||
          _vendorLabel(order.vendorId).toLowerCase().contains(query) ||
          (vendor?.name ?? '').toLowerCase().contains(query) ||
          vendorLocation.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.toLowerCase().contains(query) ||
          order.customerAddress.toLowerCase().contains(query) ||
          order.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      drawer: AdminSidebarDrawer(
        currentRoute: AdminOrdersScreen.routeName,
        onLogout: () async {
          if (!await confirmAdminLogout(context)) return;
          Navigator.pop(context);
          final logoutRoute = context.read<AppState>().logoutRouteName;
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            logoutRoute,
            (route) => false,
          );
        },
      ),
      // appBar: AppBar(
      //   backgroundColor: _kBg,
      //   foregroundColor: _kTextDark,
      //   elevation: 0,
      //   centerTitle: false,
      //   title: const Text('Admin Orders'),
      // ),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final allOrders = _sortedOrders(state.adminOrders);
            final isSuperAdmin = state.user?.role == UserRoles.superAdmin;
            final vendors = <String>[
              ...allOrders.map((order) => order.vendorId).toSet(),
            ];
            final vendorOrders = _vendorFilter == null
                ? allOrders
                : allOrders
                      .where((order) => order.vendorId == _vendorFilter)
                      .toList();
            final orders = _filteredOrders(vendorOrders);

            return ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              children: [
                _AnimatedIn(
                  animation: _animationController,
                  index: 0,
                  child: _OrdersHero(
                    orders: vendorOrders,
                    onRefresh: _refreshOrders,
                  ),
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
                if (isSuperAdmin && vendors.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _AnimatedIn(
                    animation: _animationController,
                    index: 2,
                    child: _VendorFilterBar(
                      vendors: vendors,
                      selected: _vendorFilter,
                      onSelected: (value) =>
                          setState(() => _vendorFilter = value),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                _AnimatedIn(
                  animation: _animationController,
                  index: 2,
                  child: _bootstrapping && state.adminOrders.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : orders.isEmpty
                      ? const _OrdersEmptyState()
                      : _OrdersTable(
                          orders: orders,
                          showVendor: isSuperAdmin,
                          vendorLookup: _vendorLookup,
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
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.onLogout});
  final Future<void> Function() onLogout;
  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.read<AppState>().user?.role == UserRoles.superAdmin;
    final items = [
      ('Overview', Icons.dashboard, AdminDashboardScreen.routeName),
      ('Orders', Icons.receipt_long, AdminOrdersScreen.routeName),
      if (isSuperAdmin)
        (
          'Notifications',
          Icons.notifications_active,
          AdminNotificationsScreen.routeName,
        ),
      ('Products', Icons.inventory_2, ManageProductsScreen.routeName),
      if (isSuperAdmin)
        ('Categories', Icons.category, ManageCategoriesScreen.routeName),
      if (isSuperAdmin)
        ('Banners', Icons.slideshow, ManageBannersScreen.routeName),
      if (isSuperAdmin) ('Users', Icons.groups, ManageUsersScreen.routeName),
      if (isSuperAdmin)
        (
          'Delivery partners',
          Icons.delivery_dining,
          ManageDeliveryScreen.routeName,
        ),
      ('Stock alerts', Icons.warning_amber, StockScreen.routeName),
    ];
    return Drawer(
      child: Container(
        color: _kBg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: _kOrangeLight,
                      child: Icon(Icons.admin_panel_settings, color: _kOrange),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin menu',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _kTextDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Navigate the control center',
                            style: TextStyle(color: _kTextMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE7E7E7)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final accentColors = const [
                      Color(0xFF0F766E),
                      Color(0xFFB45309),
                      Color(0xFF2563EB),
                      Color(0xFF059669),
                      Color(0xFFEA580C),
                      Color(0xFF7C3AED),
                      Color(0xFFDB2777),
                      Color(0xFFDC2626),
                    ];
                    final accent = accentColors[index % accentColors.length];
                    return Material(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context);
                          if (item.$3 != AdminOrdersScreen.routeName) {
                            Navigator.pushReplacementNamed(context, item.$3);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(item.$2, color: accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kOrange,
                      side: const BorderSide(color: _kOrange),
                      backgroundColor: _kOrangeLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
      maxLines: 1,
      textInputAction: TextInputAction.search,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kOrange, width: 1.4),
        ),
      ),
    );
  }
}

class _VendorFilterBar extends StatelessWidget {
  const _VendorFilterBar({
    required this.vendors,
    required this.selected,
    required this.onSelected,
  });

  final List<String> vendors;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: _kOrange,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Filter orders by vendor',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _kTextDark,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All vendors'),
                  selected: selected == null,
                  onSelected: (_) => onSelected(null),
                  showCheckmark: false,
                  selectedColor: _kOrange,
                  backgroundColor: const Color(0xFFF1F5F9),
                  labelStyle: TextStyle(
                    color: selected == null ? Colors.white : _kTextDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: selected == null
                        ? _kOrange
                        : const Color(0xFFE8E8E8),
                  ),
                ),
                ...vendors.map((vendor) {
                  final isSelected = selected == vendor;
                  return ChoiceChip(
                    label: Text(_vendorLabel(vendor)),
                    selected: isSelected,
                    onSelected: (_) => onSelected(isSelected ? null : vendor),
                    showCheckmark: false,
                    selectedColor: _kOrange,
                    backgroundColor: const Color(0xFFF1F5F9),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : _kTextDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                    side: BorderSide(
                      color: isSelected ? _kOrange : const Color(0xFFE8E8E8),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersHero extends StatelessWidget {
  const _OrdersHero({required this.orders, required this.onRefresh});

  final List<OrderModel> orders;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
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
    final revenue = orders
        .where((order) => order.status == OrderStatus.delivered)
        .fold<double>(0, (sum, order) => sum + order.total);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(
                  builder: (menuContext) => IconButton.filledTonal(
                    onPressed: () => Scaffold.of(menuContext).openDrawer(),
                    style: IconButton.styleFrom(
                      backgroundColor: _kOrangeLight,
                      foregroundColor: _kOrange,
                    ),
                    icon: const Icon(Icons.menu),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Orders control table',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _kTextDark,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _RefreshButton(onRefresh: onRefresh),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _kOrangeLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.receipt_long, color: _kOrange, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tap any sortable column header to reorder the table.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: _kTextMid,
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
                  color: _kOrange,
                  tint: const Color(0xFFFFF0EB),
                  index: 0,
                ),
                _HeroMetric(
                  label: 'Active',
                  value: '$active',
                  icon: Icons.local_shipping,
                  color: const Color(0xFF1D4ED8),
                  tint: const Color(0xFFEFF6FF),
                  index: 1,
                ),
                _HeroMetric(
                  label: 'Delivered',
                  value: '$delivered',
                  icon: Icons.check_circle,
                  color: const Color(0xFF0F766E),
                  tint: const Color(0xFFEAF7EF),
                  index: 2,
                ),
                _HeroMetric(
                  label: 'Revenue',
                  value: 'Rs ${revenue.toStringAsFixed(0)}',
                  icon: Icons.payments,
                  color: const Color(0xFFBE185D),
                  tint: const Color(0xFFFCE7F3),
                  index: 3,
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
    required this.tint,
    required this.index,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color tint;
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint, Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: _kTextDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      color: _kTextMid,
                      fontSize: 12,
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

class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: _loading ? null : _handleTap,
      style: IconButton.styleFrom(
        backgroundColor: _kOrangeLight,
        foregroundColor: _kOrange,
      ),
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh),
    );
  }
}

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({
    required this.orders,
    required this.showVendor,
    required this.vendorLookup,
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
    required this.onMove,
  });

  final List<OrderModel> orders;
  final bool showVendor;
  final Map<String, VendorModel> vendorLookup;
  final int sortColumnIndex;
  final bool sortAscending;
  final ValueChanged<int> onSort;
  final Future<void> Function(OrderModel order, String status) onMove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                      color: _kTextDark,
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
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      sortColumnIndex: sortColumnIndex,
                      sortAscending: sortAscending,
                      headingRowColor: WidgetStateProperty.all(
                        const Color(0xFFFFF5EF),
                      ),
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
                        if (showVendor) const DataColumn(label: Text('Vendor')),
                        if (showVendor)
                          const DataColumn(label: Text('Vendor Location')),
                        const DataColumn(label: Text('Customer')),
                        const DataColumn(label: Text('Phone')),
                        const DataColumn(label: Text('Customer Address')),
                        DataColumn(
                          label: const Text('Placed Time'),
                          onSort: (_, __) => onSort(0),
                        ),
                        DataColumn(
                          label: const Text('Accepted Time'),
                          onSort: (_, __) => onSort(1),
                        ),
                        DataColumn(
                          label: const Text('Delivered Time'),
                          onSort: (_, __) => onSort(2),
                        ),
                        DataColumn(
                          label: const Text('Status'),
                          onSort: (_, __) => onSort(3),
                        ),
                        const DataColumn(label: Text('Order Items')),
                        const DataColumn(label: Text('Payment')),
                        DataColumn(
                          label: const Text('Total'),
                          numeric: true,
                          onSort: (_, __) => onSort(4),
                        ),
                        const DataColumn(label: Text('Accepted By')),
                        const DataColumn(label: Text('Delivery Contact')),
                        const DataColumn(label: Text('Next Action')),
                      ],
                      rows: orders.asMap().entries.map((entry) {
                        final index = entry.key;
                        final order = entry.value;
                        final action = _nextAction(order.status);
                        return DataRow(
                          color: WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return const Color(0xFFFFF5EF);
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
                                        color: const Color(0xFFFFF0EB),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const SizedBox(
                                        width: 34,
                                        height: 34,
                                        child: Icon(
                                          Icons.receipt,
                                          color: _kOrange,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      order.displayOrderId,
                                      style: const TextStyle(
                                        color: _kTextDark,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (showVendor)
                              DataCell(
                                _TableCellIn(
                                  animationKey: '${order.id}-vendor',
                                  index: index,
                                  child: _VendorBadge(
                                    vendorId: order.vendorId,
                                    vendorName:
                                        vendorLookup[order.vendorId]?.name,
                                  ),
                                ),
                              ),
                            if (showVendor)
                              DataCell(
                                _TableCellIn(
                                  animationKey: '${order.id}-vendor-location',
                                  index: index,
                                  child: _VendorLocationBadge(
                                    location: _vendorLocationLabel(
                                      vendorLookup[order.vendorId],
                                    ),
                                  ),
                                ),
                              ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-customer',
                                index: index,
                                child: Text(
                                  order.customerName.isNotEmpty
                                      ? order.customerName
                                      : 'Customer',
                                  style: const TextStyle(
                                    color: _kTextDark,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-phone',
                                index: index,
                                child: Text(
                                  order.customerPhone.isNotEmpty
                                      ? order.customerPhone
                                      : '-',
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-address',
                                index: index,
                                child: Text(
                                  order.customerAddress.isNotEmpty
                                      ? order.customerAddress
                                      : order.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-placed',
                                index: index,
                                child: Text(_formatDateTime(order.createdAt)),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-accepted',
                                index: index,
                                child: Text(_formatTimeOnly(order.acceptedAt)),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-delivered',
                                index: index,
                                child: Text(_formatTimeOnly(order.deliveredAt)),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey:
                                    '${order.id}-status-${order.status.name}',
                                index: index,
                                child: _StatusBadge(status: order.status),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-items',
                                index: index,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _kOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _showOrderItems(context, order),
                                  icon: const Icon(
                                    Icons.visibility_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'View Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey: '${order.id}-payment',
                                index: index,
                                child: _PaymentBadge(
                                  method: order.paymentMethod,
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
                                    color: _kOrange,
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
                                animationKey: '${order.id}-delivery-phone',
                                index: index,
                                child: _DeliveryContactCell(order: order),
                              ),
                            ),
                            DataCell(
                              _TableCellIn(
                                animationKey:
                                    '${order.id}-action-${action?.status ?? 'done'}',
                                index: index,
                                child: _OrderActionBadge(
                                  label: action?.label ?? 'Done',
                                  isDone: action == null,
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

void _showOrderItems(BuildContext context, OrderModel order) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invoice',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ${order.displayOrderId}',
                  style: const TextStyle(
                    color: _kTextMid,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF5D6C4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _InvoiceMeta(
                          label: 'Customer',
                          value: order.customerName.isNotEmpty
                              ? order.customerName
                              : 'Customer',
                        ),
                      ),
                      Expanded(
                        child: _InvoiceMeta(
                          label: 'Phone',
                          value: order.customerPhone.isNotEmpty
                              ? order.customerPhone
                              : '-',
                        ),
                      ),
                      Expanded(
                        child: _InvoiceMeta(
                          label: 'Status',
                          value: _statusLabel(order.status),
                        ),
                      ),
                      Expanded(
                        child: _InvoiceMeta(
                          label: 'Total',
                          value: 'Rs ${order.total.toStringAsFixed(0)}',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7F9FF),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                flex: 5,
                                child: Text(
                                  'ITEM',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _kTextDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'QTY',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _kTextDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'PRICE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _kTextDark,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'TOTAL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _kTextDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: order.products.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 24),
                            itemBuilder: (context, index) {
                              final product = order.products[index];
                              final qty = index < order.quantities.length
                                  ? order.quantities[index]
                                  : 1;
                              final lineTotal = product.price * qty;
                              return Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: _kOrangeLight,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(0xFFF5D6C4),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: product.imageUrl.isNotEmpty
                                          ? Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                    Icons.shopping_bag_outlined,
                                                    color: _kOrange,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.shopping_bag_outlined,
                                              color: _kOrange,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    flex: 5,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: _kTextDark,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          product.category,
                                          style: const TextStyle(
                                            color: _kTextMid,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'x$qty',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _kTextDark,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rs ${product.price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: _kTextDark,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Rs ${lineTotal.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: _kOrange,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _InvoiceTotalBox(
                        label: 'Subtotal',
                        value:
                            'Rs ${order.products.fold<double>(0, (sum, item) => sum + (item.price * (item.stock > 0 ? item.stock : 1))).toStringAsFixed(0)}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InvoiceTotalBox(
                        label: 'Grand Total',
                        value: 'Rs ${order.total.toStringAsFixed(0)}',
                        highlighted: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: _kOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    label: const Text(
                      'Close Invoice',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _InvoiceMeta extends StatelessWidget {
  const _InvoiceMeta({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _kTextMid,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: _kTextDark,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InvoiceTotalBox extends StatelessWidget {
  const _InvoiceTotalBox({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  final String label;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? _kOrangeLight : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? _kOrange.withValues(alpha: 0.22)
              : const Color(0xFFF0F0F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _kTextMid,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: highlighted ? _kOrange : _kTextDark,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorBadge extends StatelessWidget {
  const _VendorBadge({required this.vendorId, this.vendorName});

  final String vendorId;
  final String? vendorName;

  @override
  Widget build(BuildContext context) {
    final isMain = vendorId.isEmpty || vendorId == 'main';
    final color = isMain ? const Color(0xFF0F766E) : const Color(0xFF7C3AED);
    final background = isMain
        ? const Color(0xFFCCFBF1)
        : const Color(0xFFEDE9FE);
    final label = vendorName?.trim().isNotEmpty == true
        ? vendorName!.trim()
        : _vendorLabel(vendorId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront, size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'ID: ${_vendorLabel(vendorId)}',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w700,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _VendorLocationBadge extends StatelessWidget {
  const _VendorLocationBadge({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final hasLocation = location.trim().isNotEmpty && location.trim() != '-';
    final color = hasLocation
        ? const Color(0xFF0F766E)
        : const Color(0xFF64748B);
    final background = hasLocation
        ? const Color(0xFFEAF7EF)
        : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_outlined, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            hasLocation ? location : '-',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  const _PaymentBadge({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) {
    final isPaid =
        method.toLowerCase() == 'paid' || method.toLowerCase() == 'online';
    final label = isPaid ? 'Paid' : 'COD';
    final color = isPaid ? const Color(0xFF0F766E) : const Color(0xFFB45309);
    final bg = isPaid ? const Color(0xFFEAF7EF) : const Color(0xFFFFF7ED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
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
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          'Done',
          style: TextStyle(color: _kOrange, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _OrderActionBadge extends StatelessWidget {
  const _OrderActionBadge({required this.label, required this.isDone});

  final String label;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final color = isDone ? const Color(0xFF0F766E) : const Color(0xFFB45309);
    final bg = isDone ? const Color(0xFFEAF7EF) : const Color(0xFFFFF7ED);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
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
        style: const TextStyle(color: _kTextMid, fontWeight: FontWeight.w700),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0EB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.deliveryPersonName ?? 'Accepted',
              style: const TextStyle(
                color: _kOrange,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimeOnly(
                order.acceptedAt ??
                    order.deliveryAcceptedAt ??
                    order.deliveredAt,
              ),
              style: const TextStyle(
                color: _kTextMid,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryContactCell extends StatelessWidget {
  const _DeliveryContactCell({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final name = (order.deliveryPersonName ?? '').trim();
    final phone = (order.deliveryPersonPhone ?? '').trim();

    if (order.deliveryPersonId == null && phone.isEmpty) {
      return Text(
        order.status == OrderStatus.assigned ? 'Waiting' : '-',
        style: const TextStyle(color: _kTextMid, fontWeight: FontWeight.w700),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              phone.isEmpty ? '-' : phone,
              style: const TextStyle(
                color: _kTextDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                name,
                style: const TextStyle(
                  color: _kTextMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
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
        color: _kCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.receipt_long, color: _kOrange),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No orders available yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: _kTextDark,
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

class _PlacedStateBadge extends StatelessWidget {
  const _PlacedStateBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isPlaced = status == OrderStatus.placed;
    final background = isPlaced
        ? const Color(0xFFFFF7ED)
        : const Color(0xFFF1F5F9);
    final foreground = isPlaced
        ? const Color(0xFFC2410C)
        : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isPlaced ? 'New Request' : 'Pending / Later',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w800,
          fontSize: 12,
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
    OrderStatus.outForDelivery => const _OrderAction('Deliver', 'delivered'),
    OrderStatus.delivered || OrderStatus.cancelled => null,
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
    OrderStatus.outForDelivery => const _BadgeStyle(
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
    OrderStatus.placed => 'NEW REQUEST',
    OrderStatus.accepted => 'ACCEPTED',
    OrderStatus.packed => 'PACKED',
    OrderStatus.assigned => 'ASSIGNED',
    OrderStatus.deliveryAccepted => 'DELIVERY ACCEPTED',
    OrderStatus.pickedUp => 'PICKED UP',
    OrderStatus.outForDelivery => 'OUT FOR DELIVERY',
    OrderStatus.delivered => 'DELIVERED',
    OrderStatus.cancelled => 'CANCELLED',
  };
}

String _shortId(String id) {
  if (id.length <= 8) return id;
  return id.substring(id.length - 8).toUpperCase();
}

String _vendorLabel(String vendorId) {
  final raw = vendorId.trim();
  if (raw.isEmpty || raw == 'main') return 'Main';
  return _formatVendorDisplayId(raw, null);
}

String _formatVendorDisplayId(String? vendorId, String? id) {
  final normalized = (vendorId ?? '').trim();
  final upper = normalized.toUpperCase();
  if (upper.startsWith('DMD-VENDOR-')) return upper;

  final source = (id ?? normalized).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (source.isEmpty) return 'DMD-VENDOR-0000';
  final suffix = source.length >= 4
      ? source.substring(source.length - 4)
      : source.padLeft(4, '0');
  return 'DMD-VENDOR-${suffix.toUpperCase()}';
}

String _vendorLocationLabel(VendorModel? vendor) {
  if (vendor == null) return '-';
  final parts = <String>[
    vendor.city.trim(),
    vendor.state.trim(),
  ].where((part) => part.isNotEmpty).toList();
  if (parts.isNotEmpty) {
    final cityState = parts.join(', ');
    if (vendor.pincode.trim().isNotEmpty) {
      return '$cityState - ${vendor.pincode.trim()}';
    }
    return cityState;
  }
  if (vendor.address.trim().isNotEmpty) return vendor.address.trim();
  return '-';
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[-_\s]'))
      .where((part) => part.isNotEmpty)
      .map((part) {
        return part[0].toUpperCase() + part.substring(1);
      })
      .join(' ');
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/${local.year} $hour12:$minute $amPm';
}

String _formatTimeOnly(DateTime? date) {
  if (date == null) return '-';
  final local = date.toLocal();
  final hour12 = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '$hour12:$minute $amPm';
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
