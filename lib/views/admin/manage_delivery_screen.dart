import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ManageDeliveryScreen extends StatelessWidget {
  const ManageDeliveryScreen({super.key});

  static const routeName = '/admin/delivery';

  @override
  Widget build(BuildContext context) {
    return const _AdminDeliveryPanel();
  }
}

class _AdminDeliveryPanel extends StatefulWidget {
  const _AdminDeliveryPanel();

  @override
  State<_AdminDeliveryPanel> createState() => _AdminDeliveryPanelState();
}

class _AdminDeliveryPanelState extends State<_AdminDeliveryPanel>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  late final Animation<double> _slideAnimation;

  static const _ink = Color(0xFF202629);
  static const _teal = Color(0xFF007A78);
  static const _darkTeal = Color(0xFF00625F);
  static const _mint = Color(0xFF83E6D9);
  static const _page = Color(0xFFF2F7F6);
  static const _line = Color(0xFFB7C9C7);

  static final List<_DeliveryPartner> _partners = [
    _DeliveryPartner('AM', 'Arjun M', 'North Zone', 'Bike', 'Available', 4.9, true),
    _DeliveryPartner('NR', 'Nisha R', 'Central Zone', 'EV', 'On Duty', 4.7, false),
    _DeliveryPartner('KS', 'Kavin S', 'South Zone', 'Bike', 'Available', 4.8, false),
    _DeliveryPartner('MP', 'Meera P', 'West Zone', 'Van', 'Offline', 4.5, false),
  ];

  static final List<_DispatchTask> _queue = [
    _DispatchTask(
      minutes: '08',
      priority: 'CRITICAL',
      orderId: '#ORD-9021',
      title: 'Medical Supplies - Sector 4',
      subtitle: 'Priority delivery to City General Hospital',
      tone: Color(0xFFC91F28),
      stops: 1,
    ),
    _DispatchTask(
      minutes: '15',
      priority: 'STANDARD',
      orderId: '#ORD-9025',
      title: 'Groceries Cluster - Zone B',
      subtitle: 'Multi-drop delivery (4 stops)',
      tone: _teal,
      stops: 4,
    ),
  ];

  static final List<_AlertItem> _alerts = [
    _AlertItem(
        Icons.notifications_active_rounded,
        'Late delivery risk',
        '3 orders need action',
        Color(0xFFC91F28),
        'High'),
    _AlertItem(
        Icons.inventory_2_rounded,
        'Low stock linked',
        'Tomato and milk restock',
        Color(0xFFB7791F),
        'Medium'),
    _AlertItem(
        Icons.route_rounded,
        'Zone B surge',
        'Assign 2 more partners',
        _teal,
        'Low'),
  ];

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 20000),
    )..repeat();

    _slideAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: _AnimatedIn(
                animation: _introController,
                index: 0,
                child: const _HeaderSection(),
              ),
            ),

            // Main Content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              sliver: SliverList.list(
                children: [
                  // Quick Stats Row
                  _AnimatedIn(
                    animation: _introController,
                    index: 1,
                    child: const _QuickStatsRow(),
                  ),
                  const SizedBox(height: 20),

                  // Alerts Section
                  _AnimatedIn(
                    animation: _introController,
                    index: 2,
                    child: _AlertStrip(alerts: _alerts),
                  ),
                  const SizedBox(height: 20),

                  // Delivery Partners Section
                  _AnimatedIn(
                    animation: _introController,
                    index: 3,
                    child: _PartnerPanel(partners: _partners),
                  ),
                  const SizedBox(height: 20),

                  // Dispatch Queue Section
                  _AnimatedIn(
                    animation: _introController,
                    index: 4,
                    child: _DispatchQueue(tasks: _queue),
                  ),
                  const SizedBox(height: 20),

                  // Heatmap & Metrics Section
                  _AnimatedIn(
                    animation: _introController,
                    index: 5,
                    child: _LiveHeatmap(
                      animation: _pulseController,
                      slideAnimation: _slideAnimation,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Performance Metrics Section
                  _AnimatedIn(
                    animation: _introController,
                    index: 6,
                    child: const _PerformanceMetrics(),
                  ),
                  const SizedBox(height: 20),

                  // Recent Activity Section
                  _AnimatedIn(
                    animation: _introController,
                    index: 7,
                    child: const _RecentActivity(),
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

// ==================== HEADER SECTION ====================
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF188D88), Color(0xFF007A78)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Bar
          Row(
            children: [
              const Expanded(
                child: Text(
                  'OPERATIONAL OVERVIEW',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () {},
                color: Colors.white,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () {},
                color: Colors.white,
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Title
          const Text(
            'Logistics Command Center',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Real-time delivery management dashboard',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Hero Metrics
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Wrap(
              runSpacing: 18,
              children: [
                _HeroMetric(label: 'ACTIVE', value: '1,284'),
                _MetricDivider(),
                _HeroMetric(label: 'AVAILABLE', value: '412'),
                _MetricDivider(),
                _HeroMetric(label: 'ORDERS', value: '856'),
                _MetricDivider(),
                _HeroMetric(label: 'REVENUE', value: r'$42.1k', wide: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Status Chips
          Row(
            children: [
              _StatusChip(label: 'On Time', value: '94%', color: Colors.greenAccent),
              const SizedBox(width: 12),
              _StatusChip(label: 'Delayed', value: '6%', color: Colors.orangeAccent),
              const SizedBox(width: 12),
              _StatusChip(label: 'Canceled', value: '2%', color: Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value, this.wide = false});

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: SizedBox(
        width: wide ? 150 : 96,
        child: Padding(
          padding: EdgeInsets.only(left: wide ? 16 : 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFCBEFEB),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.only(right: 16),
      color: Colors.white24,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: color, size: 8),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== QUICK STATS ROW ====================
class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            label: 'Total Deliveries',
            value: '1,284',
            icon: Icons.local_shipping_outlined,
            color: const Color(0xFF007A78),
            change: '+12.5%',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            label: 'Active Partners',
            value: '48',
            icon: Icons.people_outline,
            color: const Color(0xFF2563EB),
            change: '+4',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            label: 'Pending Orders',
            value: '23',
            icon: Icons.pending_actions_outlined,
            color: const Color(0xFFB7791F),
            change: '-6',
            isPositive: false,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
    required this.isPositive,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _AdminDeliveryPanelState._line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.green.withValues(alpha: .1) : Colors.red.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 12,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: TextStyle(
                        color: isPositive ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: _AdminDeliveryPanelState._ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF60706E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ALERT STRIP ====================
class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.alerts});

  final List<_AlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alerts & Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: _AdminDeliveryPanelState._ink,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _AnimatedAlert(item: alerts[index], delay: index),
          ),
        ),
      ],
    );
  }
}

class _AnimatedAlert extends StatelessWidget {
  const _AnimatedAlert({required this.item, required this.delay});

  final _AlertItem item;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.9, end: 1),
      duration: Duration(milliseconds: 400 + delay * 100),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(14),
        decoration: _panelDecoration(),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [item.color.withValues(alpha: .2), item.color.withValues(alpha: .08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: _AdminDeliveryPanelState._ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.priority,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF60706E),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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

// ==================== PARTNER PANEL ====================
class _PartnerPanel extends StatelessWidget {
  const _PartnerPanel({required this.partners});

  final List<_DeliveryPartner> partners;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Delivery Partners',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: _AdminDeliveryPanelState._ink,
              ),
            ),
            const Spacer(),
            _StatChip(label: 'Online', value: '12'),
            const SizedBox(width: 8),
            _StatChip(label: 'Offline', value: '4'),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: _AdminDeliveryPanelState._teal,
                shape: const StadiumBorder(),
                minimumSize: const Size(58, 32),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              child: const Text(
                'All\nZones',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, height: 1.05),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: _panelDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ...partners.map((partner) => _PartnerRow(partner: partner)),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xFF3E4A48),
        ),
      ),
    );
  }
}

class _PartnerRow extends StatelessWidget {
  const _PartnerRow({required this.partner});

  final _DeliveryPartner partner;

  @override
  Widget build(BuildContext context) {
    final offline = partner.status == 'Offline';
    final duty = partner.status == 'On Duty';
    final color = offline ? const Color(0xFFC91F28) : _AdminDeliveryPanelState._teal;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 300),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: color, width: 4),
            bottom: const BorderSide(color: _AdminDeliveryPanelState._line),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  partner.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    partner.name,
                    style: const TextStyle(
                      color: _AdminDeliveryPanelState._ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12, color: const Color(0xFF60706E)),
                      const SizedBox(width: 2),
                      Text(
                        partner.zone,
                        style: const TextStyle(
                          color: Color(0xFF344341),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.directions_car, size: 12, color: const Color(0xFF60706E)),
                      const SizedBox(width: 2),
                      Text(
                        partner.vehicle,
                        style: const TextStyle(
                          color: Color(0xFF344341),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    duty ? 'On Duty' : partner.status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                Icon(Icons.star_rounded, color: _AdminDeliveryPanelState._teal, size: 15),
                const SizedBox(width: 2),
                Text(
                  partner.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
              ],
            ),
            IconButton(
              onPressed: () {},
              tooltip: 'Partner actions',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF60706E), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== DISPATCH QUEUE ====================
class _DispatchQueue extends StatelessWidget {
  const _DispatchQueue({required this.tasks});

  final List<_DispatchTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Dispatch Queue',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: _AdminDeliveryPanelState._ink,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF246D5E).withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending_actions, color: Color(0xFF246D5E), size: 16),
                  SizedBox(width: 6),
                  Text(
                    '12 PENDING',
                    style: TextStyle(
                      color: Color(0xFF246D5E),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: _panelDecoration(),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A6B5A), Color(0xFF246D5E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(17, 12, 14, 12),
                child: const Row(
                  children: [
                    Icon(Icons.route_outlined, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Active Routes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ...tasks.map((task) => _DispatchCard(task: task)),
            ],
          ),
        ),
      ],
    );
  }
}

class _DispatchCard extends StatelessWidget {
  const _DispatchCard({required this.task});

  final _DispatchTask task;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 16, 14, 16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _AdminDeliveryPanelState._line)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFE7F0EF), const Color(0xFFD5E3E1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: _AdminDeliveryPanelState._line),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.minutes,
                    style: const TextStyle(
                      color: _AdminDeliveryPanelState._teal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'MIN',
                    style: TextStyle(
                      color: _AdminDeliveryPanelState._teal,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.tone.withValues(alpha: .15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.priority_high, color: task.tone, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              task.priority,
                              style: TextStyle(
                                color: task.tone,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F5F4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on, size: 12, color: const Color(0xFF60706E)),
                            const SizedBox(width: 4),
                            Text(
                              '${task.stops} stops',
                              style: const TextStyle(
                                color: Color(0xFF60706E),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.orderId,
                        style: const TextStyle(
                          color: Color(0xFF3E4A48),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.title,
                    style: const TextStyle(
                      color: _AdminDeliveryPanelState._ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    task.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF667370),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            backgroundColor: _AdminDeliveryPanelState._teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: const Size(0, 38),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_alt_1, size: 18),
                              SizedBox(width: 8),
                              Text('Assign', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667370),
                          minimumSize: const Size(48, 38),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: _AdminDeliveryPanelState._line),
                        ),
                        child: const Icon(Icons.map_outlined, size: 22),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF667370),
                          minimumSize: const Size(48, 38),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: _AdminDeliveryPanelState._line),
                        ),
                        child: const Icon(Icons.timer_outlined, size: 22),
                      ),
                    ],
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

// ==================== LIVE HEATMAP ====================
class _LiveHeatmap extends StatelessWidget {
  const _LiveHeatmap({required this.animation, required this.slideAnimation});

  final Animation<double> animation;
  final Animation<double> slideAnimation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _AdminDeliveryPanelState._teal.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_outlined,
                color: _AdminDeliveryPanelState._teal,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Live Zone Heatmap',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _AdminDeliveryPanelState._ink,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: .2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, color: Colors.green, size: 8),
                  SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Fullscreen',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: _panelDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.78,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: _MapPainter(animation, slideAnimation),
                    child: AnimatedBuilder(
                      animation: animation,
                      builder: (context, _) {
                        return Stack(
                          children: [
                            Positioned(
                              right: 12,
                              top: 12,
                              child: Transform.scale(
                                scale: .92 + animation.value * .08,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: .15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, color: Color(0xFFC91F28), size: 10),
                                      SizedBox(width: 6),
                                      Text(
                                        'High Demand Zone',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: _AdminDeliveryPanelState._ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: _HeatmapLegend(),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Active Routes',
                      value: '24',
                      icon: Icons.route_outlined,
                      color: _AdminDeliveryPanelState._teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Avg Response',
                      value: '4.2 min',
                      icon: Icons.timer_outlined,
                      color: const Color(0xFFB7791F),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'Coverage',
                      value: '86%',
                      icon: Icons.radar_outlined,
                      color: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF60706E),
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

class _HeatmapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendDot(color: Colors.red, label: 'High'),
          const SizedBox(width: 12),
          _LegendDot(color: Colors.orange, label: 'Medium'),
          const SizedBox(width: 12),
          _LegendDot(color: Colors.green, label: 'Low'),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ==================== PERFORMANCE METRICS ====================
class _PerformanceMetrics extends StatelessWidget {
  const _PerformanceMetrics();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Metrics',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _AdminDeliveryPanelState._ink,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: _panelDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _PerformanceCard(
                      label: 'Delivery Success',
                      value: '98.5%',
                      color: const Color(0xFF15803D),
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PerformanceCard(
                      label: 'Avg Delivery Time',
                      value: '24 min',
                      color: const Color(0xFF2563EB),
                      icon: Icons.speed_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PerformanceCard(
                      label: 'Customer Rating',
                      value: '4.8 ★',
                      color: const Color(0xFFB7791F),
                      icon: Icons.star_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0EF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF007A78), Color(0xFF83E6D9)],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'On-time delivery rate',
                    style: TextStyle(
                      color: const Color(0xFF60706E),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '70%',
                    style: TextStyle(
                      color: const Color(0xFF007A78),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: .1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF60706E),
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

// ==================== RECENT ACTIVITY ====================
class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: _AdminDeliveryPanelState._ink,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: _panelDecoration(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _ActivityItem(
                icon: Icons.delivery_dining,
                title: 'Order #ORD-9021 delivered',
                time: '2 min ago',
                color: const Color(0xFF007A78),
              ),
              const Divider(),
              _ActivityItem(
                icon: Icons.person_add,
                title: 'New partner: Rajesh K. joined',
                time: '15 min ago',
                color: const Color(0xFF2563EB),
              ),
              const Divider(),
              _ActivityItem(
                icon: Icons.warning,
                title: 'Zone B surge alert triggered',
                time: '28 min ago',
                color: const Color(0xFFB7791F),
              ),
              const Divider(),
              _ActivityItem(
                icon: Icons.trending_up,
                title: 'Order volume increased by 23%',
                time: '1 hour ago',
                color: const Color(0xFF15803D),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.time,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _AdminDeliveryPanelState._ink,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: const Color(0xFF94A3B8), size: 20),
        ],
      ),
    );
  }
}

// ==================== MAP PAINTER ====================
class _MapPainter extends CustomPainter {
  const _MapPainter(this.animation, this.slideAnimation)
      : super(repaint: animation);

  final Animation<double> animation;
  final Animation<double> slideAnimation;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF090D0F), Color(0xFF1A2528)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 1;
    for (var i = 0; i < 20; i++) {
      final x = size.width * i / 20;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
      final y = size.height * i / 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Main highways
    final highwayPaint = Paint()
      ..color = Colors.white.withValues(alpha: .15)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final path1 = Path()
      ..moveTo(size.width * .05, size.height)
      ..cubicTo(size.width * .25, size.height * .8, size.width * .35, size.height * .4, size.width * .65, 0);
    canvas.drawPath(path1, highwayPaint);

    final path2 = Path()
      ..moveTo(0, size.height * .3)
      ..cubicTo(size.width * .3, size.height * .25, size.width * .5, size.height * .6, size.width, size.height * .5);
    canvas.drawPath(path2, highwayPaint);

    // Secondary roads
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: .06)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final road1 = Path()
      ..moveTo(size.width * .15, 0)
      ..cubicTo(size.width * .25, size.height * .3, size.width * .2, size.height * .7, size.width * .4, size.height);
    canvas.drawPath(road1, roadPaint);

    // Heat zones with animation
    final heatZones = [
      [size.width * .58, size.height * .42, size.width * .38, 0.8],
      [size.width * .25, size.height * .65, size.width * .25, 0.5],
      [size.width * .78, size.height * .25, size.width * .2, 0.3],
    ];

    for (final zone in heatZones) {
      final x = zone[0] as double;
      final y = zone[1] as double;
      final radius = zone[2] as double;
      final intensity = zone[3] as double;

      final heatPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFF4444).withValues(alpha: .35 * intensity + animation.value * .15),
            const Color(0xFFFF6B00).withValues(alpha: .2 * intensity),
            const Color(0xFFFFAA00).withValues(alpha: .1 * intensity),
            Colors.transparent,
          ],
          stops: const [0, 0.3, 0.6, 1],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: radius));
      canvas.drawCircle(Offset(x, y), radius, heatPaint);
    }

    // Pulse rings
    final pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withValues(alpha: .15 + animation.value * .15);
    for (var i = 0; i < 3; i++) {
      final radius = size.width * .12 * (i + 1) * (0.8 + animation.value * 0.2);
      canvas.drawCircle(
        Offset(size.width * .58, size.height * .42),
        radius,
        pulsePaint,
      );
    }

    // Moving delivery indicators
    final positions = [
      Offset(size.width * .15 + slideAnimation.value * size.width * .3,
          size.height * .7 + slideAnimation.value * size.height * .1),
      Offset(size.width * .4 + slideAnimation.value * size.width * .2,
          size.height * .3 + slideAnimation.value * size.height * .2),
      Offset(size.width * .7 + slideAnimation.value * size.width * .15,
          size.height * .5 + slideAnimation.value * size.height * .15),
    ];

    for (final pos in positions) {
      final carPaint = Paint()
        ..color = Colors.white.withValues(alpha: .6 + animation.value * .3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 6, carPaint);

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: pos, radius: 20));
      canvas.drawCircle(pos, 20, glowPaint);
    }

    // Zone labels
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Zone A',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width * .72, size.height * .35));

    final textPainter2 = TextPainter(
      text: const TextSpan(
        text: 'Zone B',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter2.layout();
    textPainter2.paint(canvas, Offset(size.width * .12, size.height * .55));

    // Demand indicators
    final demandLocations = [
      [size.width * .58, size.height * .42, Color(0xFFC91F28)],
      [size.width * .25, size.height * .65, Color(0xFFB7791F)],
    ];

    for (final loc in demandLocations) {
      final x = loc[0] as double;
      final y = loc[1] as double;
      final color = loc[2] as Color;

      final dotPaint = Paint()..color = color;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);

      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: .2),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 15));
      canvas.drawCircle(Offset(x, y), 15, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.slideAnimation != slideAnimation;
  }
}

// ==================== ANIMATED IN ====================
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
      curve: Interval((index * .08).clamp(0, .7), 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .04), end: Offset.zero)
            .animate(curved),
        child: child,
      ),
    );
  }
}

// ==================== HELPERS ====================
BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _AdminDeliveryPanelState._line),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .06),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

// ==================== DATA MODELS ====================
class _DeliveryPartner {
  const _DeliveryPartner(
    this.initials,
    this.name,
    this.zone,
    this.vehicle,
    this.status,
    this.rating,
    this.online,
  );

  final String initials;
  final String name;
  final String zone;
  final String vehicle;
  final String status;
  final double rating;
  final bool online;
}

class _DispatchTask {
  const _DispatchTask({
    required this.minutes,
    required this.priority,
    required this.orderId,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.stops,
  });

  final String minutes;
  final String priority;
  final String orderId;
  final String title;
  final String subtitle;
  final Color tone;
  final int stops;
}

class _AlertItem {
  const _AlertItem(this.icon, this.title, this.detail, this.color, this.priority);

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
  final String priority;
}