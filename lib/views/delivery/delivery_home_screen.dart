import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'delivery_earnings_screen.dart';
import 'delivery_order_screen.dart';
import 'live_tracking_screen.dart';

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});

  static const routeName = '/delivery';

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen>
    with TickerProviderStateMixin {
  late Future<List<OrderModel>> _openOrdersFuture;
  late AnimationController _motionController;
  late AnimationController _entranceController;
  bool _acceptingOrders = true;

  @override
  void initState() {
    super.initState();
    _openOrdersFuture = _loadOpenOrders();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7200),
    )..repeat();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _motionController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<List<OrderModel>> _loadOpenOrders() {
    return context.read<AppState>().availableDeliveryOrders();
  }

  Future<void> _refreshOrders() async {
    setState(() => _openOrdersFuture = _loadOpenOrders());
    await _openOrdersFuture;
  }

  Future<void> _openOrders() async {
    await Navigator.pushNamed(context, DeliveryOrderScreen.routeName);
    if (!mounted) return;
    setState(() => _openOrdersFuture = _loadOpenOrders());
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EA),
      bottomNavigationBar: BottomNavBar(
        index: 2,
        onTap: (index) => BottomNavBar.navigate(context, index),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF103D32),
          onRefresh: _refreshOrders,
          child: FutureBuilder<List<OrderModel>>(
            future: _openOrdersFuture,
            builder: (context, snapshot) {
              final openOrders = snapshot.data ?? const <OrderModel>[];
              final loading = !snapshot.hasData && !snapshot.hasError;

              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  22 + bottomInset + kBottomNavigationBarHeight,
                ),
                children: [
                  _DashboardHeader(
                    acceptingOrders: _acceptingOrders,
                    onRefresh: _refreshOrders,
                    onToggleAvailability: () {
                      setState(() => _acceptingOrders = !_acceptingOrders);
                    },
                  ),
                  const SizedBox(height: 14),
                  _EntranceItem(
                    controller: _entranceController,
                    order: 0,
                    child: _MotionHero(
                      controller: _motionController,
                      openOrders: openOrders.length,
                      loading: loading,
                      acceptingOrders: _acceptingOrders,
                      onOpenOrders: _openOrders,
                      onLiveTracking: () {
                        Navigator.pushNamed(
                          context,
                          LiveTrackingScreen.routeName,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EntranceItem(
                    controller: _entranceController,
                    order: 1,
                    child: _MetricStrip(openOrders: openOrders.length),
                  ),
                  const SizedBox(height: 14),
                  _EntranceItem(
                    controller: _entranceController,
                    order: 2,
                    child: _QuickActions(
                      onOrders: _openOrders,
                      onTracking: () {
                        Navigator.pushNamed(
                          context,
                          LiveTrackingScreen.routeName,
                        );
                      },
                      onEarnings: () {
                        Navigator.pushNamed(
                          context,
                          DeliveryEarningsScreen.routeName,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  _EntranceItem(
                    controller: _entranceController,
                    order: 3,
                    child: _ActiveRoutes(
                      orders: openOrders,
                      loading: loading,
                      onOpenOrders: _openOrders,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.acceptingOrders,
    required this.onRefresh,
    required this.onToggleAvailability,
  });

  final bool acceptingOrders;
  final VoidCallback onRefresh;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF173B33),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF173B33).withValues(alpha: .2),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.delivery_dining, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Command',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF16231F),
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                acceptingOrders ? 'Online and ready' : 'Paused for now',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF68706B),
                    ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: acceptingOrders,
          activeColor: const Color(0xFF173B33),
          onChanged: (_) => onToggleAvailability(),
        ),
        IconButton.filledTonal(
          onPressed: onRefresh,
          icon: const Icon(Icons.sync),
          tooltip: 'Refresh',
        ),
      ],
    );
  }
}

class _MotionHero extends StatelessWidget {
  const _MotionHero({
    required this.controller,
    required this.openOrders,
    required this.loading,
    required this.acceptingOrders,
    required this.onOpenOrders,
    required this.onLiveTracking,
  });

  final AnimationController controller;
  final int openOrders;
  final bool loading;
  final bool acceptingOrders;
  final VoidCallback onOpenOrders;
  final VoidCallback onLiveTracking;

  @override
  Widget build(BuildContext context) {
    final waitingLabel = loading ? 'Scanning' : _openOrdersLabel(openOrders);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          constraints: const BoxConstraints(minHeight: 286),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFF0D241F),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D241F).withValues(alpha: .22),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _AnimatedRoutePainter(controller.value),
                ),
              ),
              Positioned(
                right: -20,
                top: -18,
                child: _OrbitBadge(progress: controller.value),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusPill(acceptingOrders: acceptingOrders),
                    const SizedBox(height: 26),
                    Text(
                      waitingLabel,
                      style:
                          Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 250,
                      child: Text(
                        loading
                            ? 'Dispatch is checking the queue.'
                            : openOrders == 0
                                ? 'No pickup pressure. Keep your shift open.'
                                : 'Fresh pickup requests are ready for route planning.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: .76),
                              height: 1.35,
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE8FF72),
                            foregroundColor: const Color(0xFF17231F),
                            minimumSize: const Size(126, 46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: onOpenOrders,
                          icon: const Icon(Icons.inventory_2_outlined),
                          label: const Text('Pickups'),
                        ),
                        const SizedBox(width: 10),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor:
                                Colors.white.withValues(alpha: .12),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: onLiveTracking,
                          icon: const Icon(Icons.near_me_outlined),
                          tooltip: 'Live tracking',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _MiniRoutePanel(progress: controller.value),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.acceptingOrders});

  final bool acceptingOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            acceptingOrders ? Icons.bolt : Icons.pause_circle_outline,
            size: 16,
            color: const Color(0xFFE8FF72),
          ),
          const SizedBox(width: 6),
          Text(
            acceptingOrders ? 'Accepting orders' : 'Shift paused',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniRoutePanel extends StatelessWidget {
  const _MiniRoutePanel({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: .14)),
      ),
      child: Row(
        children: [
          _RouteDot(color: const Color(0xFFE8FF72), active: true),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: LinearProgressIndicator(
                value: .38 + (math.sin(progress * math.pi * 2) + 1) * .16,
                minHeight: 4,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: Colors.white.withValues(alpha: .14),
                color: const Color(0xFFE8FF72),
              ),
            ),
          ),
          _RouteDot(color: Colors.white.withValues(alpha: .82), active: false),
          const SizedBox(width: 10),
          Text(
            '18 min',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _RouteDot extends StatelessWidget {
  const _RouteDot({required this.color, required this.active});

  final Color color;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 14 : 10,
      height: active ? 14 : 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .45),
                  blurRadius: 16,
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.openOrders});

  final int openOrders;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric('Delivered', '12', Icons.check_circle_outline, Color(0xFF0F7F58)),
      _Metric('Queue', '$openOrders', Icons.local_shipping, Color(0xFFC78417)),
      _Metric('Rating', '4.8', Icons.star_outline, Color(0xFF2556A4)),
      _Metric('Payout', 'Rs 860', Icons.payments_outlined, Color(0xFF7A3EA1)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.52,
      ),
      itemBuilder: (context, index) => _MetricTile(metric: metrics[index]),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2DED0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon, size: 18, color: metric.color),
              ),
              const Spacer(),
              Icon(Icons.trending_up, size: 16, color: metric.color),
            ],
          ),
          Text(
            metric.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF16231F),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
          ),
          Text(
            metric.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF66706B),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOrders,
    required this.onTracking,
    required this.onEarnings,
  });

  final VoidCallback onOrders;
  final VoidCallback onTracking;
  final VoidCallback onEarnings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Orders',
            icon: Icons.assignment_outlined,
            color: const Color(0xFF173B33),
            onTap: onOrders,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Map',
            icon: Icons.map_outlined,
            color: const Color(0xFF2556A4),
            onTap: onTracking,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: 'Pay',
            icon: Icons.account_balance_wallet_outlined,
            color: const Color(0xFF7A3EA1),
            onTap: onEarnings,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 76,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: .18)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 7),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRoutes extends StatelessWidget {
  const _ActiveRoutes({
    required this.orders,
    required this.loading,
    required this.onOpenOrders,
  });

  final List<OrderModel> orders;
  final bool loading;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) {
    final visibleOrders = orders.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Active pickups',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF16231F),
                    letterSpacing: 0,
                  ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onOpenOrders,
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          const _RouteSkeleton()
        else if (visibleOrders.isEmpty)
          const _EmptyRouteCard()
        else
          ...visibleOrders.map((order) => _RouteCard(order: order)),
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF173B33),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '#${order.id.length > 6 ? order.id.substring(0, 6) : order.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16231F),
                        ),
                      ),
                    ),
                    Text(
                      'Rs ${order.total.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F7F58),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  order.address.isEmpty
                      ? 'Pickup address pending'
                      : order.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF68706B),
                      ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _statusProgress(order.status),
                    minHeight: 5,
                    backgroundColor: const Color(0xFFECE7D8),
                    color: const Color(0xFF173B33),
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

class _EmptyRouteCard extends StatelessWidget {
  const _EmptyRouteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2DED0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF0F7F58).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.hourglass_empty, color: Color(0xFF0F7F58)),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('No active pickups in the queue.')),
        ],
      ),
    );
  }
}

class _RouteSkeleton extends StatelessWidget {
  const _RouteSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2DED0)),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _OrbitBadge extends StatelessWidget {
  const _OrbitBadge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final angle = progress * math.pi * 2;

    return SizedBox(
      width: 158,
      height: 158,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE8FF72).withValues(alpha: .2),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(math.cos(angle) * 48, math.sin(angle) * 48),
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFE8FF72),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Icon(Icons.route, color: Color(0xFFE8FF72), size: 42),
        ],
      ),
    );
  }
}

class _AnimatedRoutePainter extends CustomPainter {
  const _AnimatedRoutePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: .055)
      ..strokeWidth = 1;
    final routePaint = Paint()
      ..color = const Color(0xFFE8FF72).withValues(alpha: .55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mutedRoutePaint = Paint()
      ..color = Colors.white.withValues(alpha: .09)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final drift = math.sin(progress * math.pi * 2) * 10;
    for (var x = -40.0 + drift; x < size.width + 40; x += 38) {
      canvas.drawLine(Offset(x, 0), Offset(x + 64, size.height), gridPaint);
    }
    for (var y = 26.0 - drift; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 26), gridPaint);
    }

    final route = Path()
      ..moveTo(18, size.height - 54)
      ..cubicTo(
        size.width * .25,
        size.height - 112,
        size.width * .52,
        96 + drift,
        size.width - 30,
        58,
      );
    canvas.drawPath(route, mutedRoutePaint);

    final metric = route.computeMetrics().first;
    final visible = metric.extractPath(0, metric.length * (.35 + progress * .45));
    canvas.drawPath(visible, routePaint);

    for (final point in [
      Offset(28, size.height - 58),
      Offset(size.width * .58, 102 + drift * .3),
      Offset(size.width - 34, 60),
    ]) {
      canvas.drawCircle(point, 7, Paint()..color = const Color(0xFFE8FF72));
      canvas.drawCircle(
        point,
        18,
        Paint()..color = const Color(0xFFE8FF72).withValues(alpha: .12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedRoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _EntranceItem extends StatelessWidget {
  const _EntranceItem({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (order * .12).clamp(0.0, .7);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, 1, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

String _openOrdersLabel(int count) {
  return count == 1 ? '1 waiting' : '$count waiting';
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
