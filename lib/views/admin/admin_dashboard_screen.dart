import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../mascot/walking_mascot_widget.dart';
import '../../providers/app_state.dart';
import '../../widgets/animated_chart.dart';
import 'audit_logs_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
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
  static const double _desktopBreakpoint = 1024;

  bool _isMenuOpen = true;

  @override
  Widget build(BuildContext context) {
    final destinations = _adminDestinations(context);
    final isDesktop =
        MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin dashboard'),
        leading: isDesktop
            ? null
            : IconButton(
                tooltip: _isMenuOpen ? 'Close menu' : 'Open menu',
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    _isMenuOpen ? Icons.close : Icons.menu,
                    key: ValueKey(_isMenuOpen),
                  ),
                ),
                onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
              ),
      ),
      body: SafeArea(
        child: isDesktop
            ? _AdminDesktopLayout(destinations: destinations)
            : _AdminMobileLayout(
                destinations: destinations,
                isMenuOpen: _isMenuOpen,
                onCloseMenu: () => setState(() => _isMenuOpen = false),
              ),
      ),
    );
  }

  List<_AdminDestination> _adminDestinations(BuildContext context) {
    return [
      _AdminDestination(
        title: 'Orders',
        subtitle: 'Track and assign',
        detail: 'Open orders, assignment queue, and fulfilment status.',
        icon: Icons.receipt_long,
        accent: const Color(0xFF0F766E),
        onTap: () => Navigator.pushNamed(context, AdminOrdersScreen.routeName),
      ),
      _AdminDestination(
        title: 'Notifications',
        subtitle: 'Stock and delay alerts',
        detail: 'Review low-stock warnings and late delivery updates.',
        icon: Icons.notifications_active,
        accent: const Color(0xFFB45309),
        onTap: () =>
            Navigator.pushNamed(context, AdminNotificationsScreen.routeName),
      ),
      _AdminDestination(
        title: 'Products',
        subtitle: 'Add, edit, delete',
        detail: 'Keep catalog items, prices, and visibility current.',
        icon: Icons.inventory_2,
        accent: const Color(0xFF2563EB),
        onTap: () =>
            Navigator.pushNamed(context, ManageProductsScreen.routeName),
      ),
      _AdminDestination(
        title: 'Users',
        subtitle: 'Role-based access',
        detail: 'Manage accounts, permissions, and admin access.',
        icon: Icons.groups,
        accent: const Color(0xFF7C3AED),
        onTap: () => Navigator.pushNamed(context, ManageUsersScreen.routeName),
      ),
      _AdminDestination(
        title: 'Delivery partners',
        subtitle: 'Assignments and status',
        detail: 'Monitor riders, availability, and delivery workload.',
        icon: Icons.delivery_dining,
        accent: const Color(0xFFDB2777),
        onTap: () =>
            Navigator.pushNamed(context, ManageDeliveryScreen.routeName),
      ),
      _AdminDestination(
        title: 'Stock alerts',
        subtitle: 'Low inventory',
        detail: 'Catch products that need restock before orders fail.',
        icon: Icons.warning_amber,
        accent: const Color(0xFFDC2626),
        onTap: () => Navigator.pushNamed(context, StockScreen.routeName),
      ),
      _AdminDestination(
        title: 'Audit logs',
        subtitle: 'Critical actions',
        detail: 'Trace sensitive changes and admin activity.',
        icon: Icons.history,
        accent: const Color(0xFF475569),
        onTap: () => Navigator.pushNamed(context, AuditLogsScreen.routeName),
      ),
    ];
  }
}

class _AdminMobileLayout extends StatelessWidget {
  const _AdminMobileLayout({
    required this.destinations,
    required this.isMenuOpen,
    required this.onCloseMenu,
  });

  final List<_AdminDestination> destinations;
  final bool isMenuOpen;
  final VoidCallback onCloseMenu;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation);

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: isMenuOpen
              ? _AdminMenuPanel(
                  key: const ValueKey('admin-menu-open'),
                  destinations: destinations,
                  onClose: onCloseMenu,
                  onNavigate: (destination) {
                    onCloseMenu();
                    destination.onTap();
                  },
                )
              : const _AdminMenuClosedState(key: ValueKey('admin-menu-closed')),
        ),
      ],
    );
  }
}

class _AdminMenuClosedState extends StatelessWidget {
  const _AdminMenuClosedState({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 1);
  }
}

class _AdminDesktopLayout extends StatelessWidget {
  const _AdminDesktopLayout({required this.destinations});

  final List<_AdminDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 390,
          child: _AdminSidebar(destinations: destinations),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            children: [
              _AdminOverview(destinations: destinations, showActions: false),
              const SizedBox(height: 12),
              const WalkingMascotWidget(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({required this.destinations});

  final List<_AdminDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F8F5),
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: destinations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _AdminSidebarTile(destination: destinations[index]);
        },
      ),
    );
  }
}

class _AdminSidebarTile extends StatelessWidget {
  const _AdminSidebarTile({required this.destination});

  final _AdminDestination destination;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: destination.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              Icon(
                destination.icon,
                color: const Color(0xFF262626),
                size: 31,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: const Color(0xFF3E3E3E),
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.subtitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: const Color(0xFF1D1D1D),
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOverview extends StatelessWidget {
  const _AdminOverview({
    super.key,
    required this.destinations,
    this.showActions = true,
  });

  final List<_AdminDestination> destinations;
  final bool showActions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: context.read<AppState>().adminDashboard(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _DashboardError(message: snapshot.error.toString());
            }
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }

            final data = snapshot.data!;
            return _AdminSummary(data: data);
          },
        ),
        if (showActions) ...[
          const SizedBox(height: 16),
          Text(
            'Control center',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...destinations.map(
            (destination) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AdminActionTile(destination: destination),
            ),
          ),
        ],
        const SizedBox(height: 8),
        const SizedBox(
          height: 140,
          child: AnimatedChart(values: [52, 88, 40, 96, 72]),
        ),
      ],
    );
  }
}

class _AdminMenuPanel extends StatelessWidget {
  const _AdminMenuPanel({
    super.key,
    required this.destinations,
    required this.onClose,
    required this.onNavigate,
  });

  final List<_AdminDestination> destinations;
  final VoidCallback onClose;
  final ValueChanged<_AdminDestination> onNavigate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admin menu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Close menu',
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            ...destinations.map(
              (destination) => _AdminMenuRow(
                destination: destination,
                onTap: () => onNavigate(destination),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSummary extends StatelessWidget {
  const _AdminSummary({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _SummaryMetric('Today Orders', data['todayOrders']),
      _SummaryMetric('Pending Orders', data['pendingOrders']),
      _SummaryMetric('Packed Orders', data['packedOrders']),
      _SummaryMetric('Out for Delivery', data['outForDeliveryOrders']),
      _SummaryMetric('Completed Orders', data['completedOrders']),
      _SummaryMetric('Cancelled Orders', data['cancelledOrders']),
      _SummaryMetric('Today Revenue', data['todayRevenue'], isCurrency: true),
      _SummaryMetric('Low Stock Products', data['lowStockProducts']),
      _SummaryMetric('Available Delivery', data['availableDeliveryPersons']),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12372A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today at a glance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metrics
                  .map(
                    (metric) => _SummaryPill(
                      label: metric.label,
                      value: metric.value,
                      isCurrency: metric.isCurrency,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message});

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
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFBE123C),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    this.isCurrency = false,
  });

  final String label;
  final Object? value;
  final bool isCurrency;

  @override
  Widget build(BuildContext context) {
    final amount = value is num ? (value as num).toDouble() : 0;
    final displayValue = isCurrency
        ? 'Rs ${amount.toStringAsFixed(0)}'
        : '${value ?? 0}';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$displayValue $label',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryMetric {
  const _SummaryMetric(this.label, this.value, {this.isCurrency = false});

  final String label;
  final Object? value;
  final bool isCurrency;
}

class _AdminActionTile extends StatelessWidget {
  const _AdminActionTile({required this.destination});

  final _AdminDestination destination;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: destination.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: destination.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const SizedBox(width: 4, height: 58),
              ),
              const SizedBox(width: 12),
              _DestinationIcon(destination: destination),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: const Color(0xFF475569),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destination.subtitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF17211B),
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      destination.detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminMenuRow extends StatelessWidget {
  const _AdminMenuRow({required this.destination, required this.onTap});

  final _AdminDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 0,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: _DestinationIcon(destination: destination, compact: true),
      title: Text(
        destination.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(destination.subtitle),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}

class _DestinationIcon extends StatelessWidget {
  const _DestinationIcon({required this.destination, this.compact = false});

  final _AdminDestination destination;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 46.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: destination.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          destination.icon,
          color: destination.accent,
          size: compact ? 22 : 26,
        ),
      ),
    );
  }
}

class _AdminDestination {
  const _AdminDestination({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String detail;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}
