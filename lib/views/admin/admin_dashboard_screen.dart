import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../providers/app_state.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'audit_logs_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'stock_screen.dart';

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
      drawer: _AdminDrawer(
        selectedIndex: _selectedIndex,
        destinations: destinations,
        onSelect: (index) {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        leading: IconButton(
          tooltip: 'Menu',
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFF9933),
              Color(0xFFFFFFFF),
              Color(0xFF138808),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
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
  });

  final int selectedIndex;
  final List<_AdminSection> destinations;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
            stops: [0.0, 0.65, 1.0],
          ),
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
                      backgroundColor: Colors.white,
                      child: Icon(Icons.admin_panel_settings, color: Color(0xFF0F766E)),
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
                                ),
                          ),
                          const Text('Select a section to view its content'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: destinations.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final section = destinations[index];
                    final selected = index == selectedIndex;
                    return Material(
                      color: selected ? Colors.white.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
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
                                        color: selected
                                            ? const Color(0xFF0F766E)
                                            : const Color(0xFF17211B),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      section.subtitle,
                                      style: TextStyle(
                                        color: Colors.black.withValues(alpha: 0.62),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
        FutureBuilder<Map<String, dynamic>>(
          future: context.read<AppState>().adminDashboard(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _StatusCard(message: snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ));
            }
            final data = snapshot.data!;
            return _StatsGrid(data: data);
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
            stops: [0.0, 0.55, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Positioned(
            //   top: 14,
            //   left: 14,
            //   child: IconButton.filledTonal(
            //     onPressed: onOpenMenu,
            //     icon: const Icon(Icons.menu),
            //   ),
            // ),
            Positioned(
              right: 12,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                // decoration: BoxDecoration(
                //   color: Colors.white.withValues(alpha: 0.86),
                //   borderRadius: BorderRadius.circular(999),
                // ),
                // child: const Text(
                //   'India-themed control center',
                //   style: TextStyle(fontWeight: FontWeight.w800),
                // ),
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
                          color: const Color(0xFF17211B),
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Track orders, products, categories, users, and delivery operations from one place.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2A24),
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

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Today Orders', data['todayOrders']),
      _Metric('Pending', data['pendingOrders']),
      _Metric('Revenue', data['todayRevenue'], currency: true),
      _Metric('Low Stock', data['lowStockProducts']),
      _Metric('Delivery', data['availableDeliveryPersons']),
      _Metric('Completed', data['completedOrders']),
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
            color: Colors.white.withValues(alpha: 0.84),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.6),
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
                  color: Color(0xFF0F766E),
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
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
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
