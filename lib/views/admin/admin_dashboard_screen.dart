import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'audit_logs_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_products_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_users_screen.dart';
import 'stock_screen.dart';

const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  static const routeName = '/admin';

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: _AdminDrawer(
        selectedIndex: _selectedIndex,
        destinations: destinations,
        onSelect: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
        onLogout: () async {
          Navigator.pop(context);
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/admin/login',
            (route) => false,
          );
        },
      ),
      // appBar: AppBar(
      //   backgroundColor: _kBg,
      //   title: const Text('Admin dashboard'),
      //   foregroundColor: _kTextDark,
      //   elevation: 0,
      //   centerTitle: false,
      //   leading: IconButton(
      //     tooltip: 'Menu',
      //     icon: const Icon(Icons.menu),
      //     onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      //   ),
      //   actions: [
      //     IconButton(
      //       tooltip: 'Refresh',
      //       onPressed: () => setState(() {}),
      //       icon: const Icon(Icons.refresh),
      //     ),
      //   ],
      // ),
      body: Container(
        decoration: const BoxDecoration(
          color: _kBg,
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _selectedBody(destinations[_selectedIndex]),
          ),
        ),
      ),
    );
  }

  Widget _selectedBody(_AdminSection section) {
    return KeyedSubtree(
      key: ValueKey(section.title),
      child: section.title == 'Overview'
          ? _AdminOverviewPanel(onOpenMenu: () => _scaffoldKey.currentState?.openDrawer())
          : section.builder(context),
    );
  }

  List<_AdminSection> _destinations(BuildContext context) {
    return [
      _AdminSection(
        title: 'Overview',
        subtitle: 'Today at a glance',
        icon: Icons.dashboard,
        accent: const Color(0xFF0F766E),
        builder: (_) => const SizedBox.shrink(),
      ),
      _AdminSection(
        title: 'Orders',
        subtitle: 'Track and assign',
        icon: Icons.receipt_long,
        accent: const Color(0xFF0F766E),
        builder: (_) => const AdminOrdersScreen(),
      ),
      _AdminSection(
        title: 'Notifications',
        subtitle: 'Stock and delay alerts',
        icon: Icons.notifications_active,
        accent: const Color(0xFFB45309),
        builder: (_) => const AdminNotificationsScreen(),
      ),
      _AdminSection(
        title: 'Products',
        subtitle: 'Add, edit, delete',
        icon: Icons.inventory_2,
        accent: const Color(0xFF2563EB),
        builder: (_) => const ManageProductsScreen(),
      ),
      _AdminSection(
        title: 'Categories',
        subtitle: 'Add images and details',
        icon: Icons.category,
        accent: const Color(0xFF059669),
        builder: (_) => const ManageCategoriesScreen(),
      ),
      _AdminSection(
        title: 'Banners',
        subtitle: 'Manage home sliders',
        icon: Icons.slideshow,
        accent: const Color(0xFFEA580C),
        builder: (_) => const ManageBannersScreen(),
      ),
      _AdminSection(
        title: 'Users',
        subtitle: 'Role-based access',
        icon: Icons.groups,
        accent: const Color(0xFF7C3AED),
        builder: (_) => const ManageUsersScreen(),
      ),
      _AdminSection(
        title: 'Delivery partners',
        subtitle: 'Assignments and status',
        icon: Icons.delivery_dining,
        accent: const Color(0xFFDB2777),
        builder: (_) => const ManageDeliveryScreen(),
      ),
      _AdminSection(
        title: 'Stock alerts',
        subtitle: 'Low inventory',
        icon: Icons.warning_amber,
        accent: const Color(0xFFDC2626),
        builder: (_) => const StockScreen(),
      ),
      _AdminSection(
        title: 'Audit logs',
        subtitle: 'Critical actions',
        icon: Icons.history,
        accent: const Color(0xFF475569),
        builder: (_) => const AuditLogsScreen(),
      ),
    ];
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelect,
    required this.onLogout,
  });

  final int selectedIndex;
  final List<_AdminSection> destinations;
  final ValueChanged<int> onSelect;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          color: _kBg,
        ),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin menu',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: _kTextDark,
                                ),
                          ),
                          const Text(
                            'Select a section to view its content',
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
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final section = destinations[index];
                    final selected = index == selectedIndex;
                    return Material(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(18),
                      elevation: selected ? 2 : 0,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => onSelect(index),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: section.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(section.icon, color: section.accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: selected ? _kOrange : _kTextDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      section.subtitle,
                                      style: TextStyle(
                                        color: _kTextMid,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: selected ? _kOrange : _kTextMid),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _kOrangeLight,
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

class _AdminOverviewPanel extends StatelessWidget {
  const _AdminOverviewPanel({required this.onOpenMenu});

  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        _HeroCard(onOpenMenu: onOpenMenu),
        const SizedBox(height: 16),
        FutureBuilder<void>(
          future: Future.microtask(() => context.read<AppState>().loadAdminOrders()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _StatusCard(message: snapshot.error.toString());
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                context.read<AppState>().adminOrders.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            }
            final orders = context.watch<AppState>().adminOrders;
            return _StatsGrid(orders: orders);
          },
        ),
        const SizedBox(height: 16),
        const WalkingMascotWidget(),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onOpenMenu});

  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 14,
              left: 14,
              child: IconButton.filledTonal(
                onPressed: onOpenMenu,
                style: IconButton.styleFrom(
                  backgroundColor: _kOrangeLight,
                  foregroundColor: _kOrange,
                ),
                icon: const Icon(Icons.menu),
              ),
            ),
            Positioned(
              top: 14,
              left: 68,
              child: _RefreshButton(onRefresh: () async {
                final state = context.read<AppState>();
                await state.loadAdminOrders();
                await state.loadProducts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dashboard refreshed')),
                  );
                }
              }),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Overview',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _kOrange,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track orders, products, categories, users, and delivery operations from one place.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kTextMid,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _StatsGrid extends StatelessWidget {
  _StatsGrid({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final orderPlaced = orders.where((order) => order.status == OrderStatus.placed).length;
    final accepted = orders.where((order) => order.status == OrderStatus.accepted).length;
    final pickup = orders
        .where((order) => order.status == OrderStatus.assigned || order.status == OrderStatus.pickedUp)
        .length;
    final delivered = orders.where((order) => order.status == OrderStatus.delivered).length;
    final revenue = orders.fold<double>(0, (sum, order) => sum + order.total);
    final lowStock = context.select<AppState, int>(
      (state) => state.products.where((product) => product.stock <= 15 && product.stock >= 0).length,
    );

    final metrics = [
      _Metric('Total Orders', orders.length),
      _Metric('Order Placed', orderPlaced),
      _Metric('Order Accepted', accepted),
      _Metric('Pickup', pickup),
      _Metric('Delivered', delivered),
      _Metric('Revenue', revenue, currency: true),
      _Metric('Low Stock', lowStock),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF0F0F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: TextStyle(
                  color: _kTextMid,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                metric.currency
                    ? 'Rs ${(metric.value is num ? (metric.value as num).toDouble() : 0).toStringAsFixed(0)}'
                    : '${metric.value ?? 0}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: _kOrange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Text(message),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, {this.currency = false});

  final String label;
  final Object? value;
  final bool currency;
}

class _AdminSection {
  const _AdminSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final WidgetBuilder builder;
}
