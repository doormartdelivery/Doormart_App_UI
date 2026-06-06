import 'package:flutter/material.dart';

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

  static const _ink = Color(0xFF202629);
  static const _teal = Color(0xFF007A78);
  static const _darkTeal = Color(0xFF00625F);
  static const _mint = Color(0xFF83E6D9);
  static const _page = Color(0xFFF2F7F6);
  static const _line = Color(0xFFB7C9C7);

  static final List<_DeliveryPartner> _partners = [
    _DeliveryPartner('AM', 'Arjun M', 'North Zone', 'Bike', 'Available', 4.9),
    _DeliveryPartner('NR', 'Nisha R', 'Central Zone', 'EV', 'On Duty', 4.7),
    _DeliveryPartner('KS', 'Kavin S', 'South Zone', 'Bike', 'Available', 4.8),
    _DeliveryPartner('MP', 'Meera P', 'West Zone', 'Van', 'Offline', 4.5),
  ];

  static final List<_DispatchTask> _queue = [
    _DispatchTask(
      minutes: '08',
      priority: 'CRITICAL',
      orderId: '#ORD-9021',
      title: 'Medical Supplies - Sector 4',
      subtitle: 'Priority delivery to City General Hospital',
      tone: Color(0xFFC91F28),
    ),
    _DispatchTask(
      minutes: '15',
      priority: 'STANDARD',
      orderId: '#ORD-9025',
      title: 'Groceries Cluster - Zone B',
      subtitle: 'Multi-drop delivery (4 stops)',
      tone: _teal,
    ),
  ];

  static final List<_AlertItem> _alerts = [
    _AlertItem(Icons.notifications_active_rounded, 'Late delivery risk', '3 orders need action', Color(0xFFC91F28)),
    _AlertItem(Icons.inventory_2_rounded, 'Low stock linked', 'Tomato and milk restock', Color(0xFFB7791F)),
    _AlertItem(Icons.route_rounded, 'Zone B surge', 'Assign 2 more partners', _teal),
  ];

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _introController.dispose();
    _pulseController.dispose();
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
            SliverToBoxAdapter(
              child: _AnimatedIn(
                animation: _introController,
                index: 0,
                child: const _HeroPanel(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              sliver: SliverList.list(
                children: [
                  _AnimatedIn(
                    animation: _introController,
                    index: 1,
                    child: _AlertStrip(alerts: _alerts),
                  ),
                  const SizedBox(height: 16),
                  _AnimatedIn(
                    animation: _introController,
                    index: 2,
                    child: _PartnerPanel(partners: _partners),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedIn(
                    animation: _introController,
                    index: 3,
                    child: _DispatchQueue(tasks: _queue),
                  ),
                  const SizedBox(height: 24),
                  _AnimatedIn(
                    animation: _introController,
                    index: 4,
                    child: _LiveHeatmap(animation: _pulseController),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  static const _teal = _AdminDeliveryPanelState._teal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF188D88), _teal],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Logistics Command\nCenter',
            style: TextStyle(
              color: Colors.white,
              fontSize: 31,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .12),
              border: Border.all(color: Colors.white.withValues(alpha: .24)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Wrap(
              runSpacing: 18,
              children: [
                _HeroMetric(label: 'ACTIVE', value: '1,284'),
                _MetricDivider(),
                _HeroMetric(label: 'AVAILABLE', value: '412'),
                _MetricDivider(),
                _HeroMetric(label: 'ORDERS', value: '856'),
                _HeroMetric(label: 'REVENUE', value: r'$42.1k', wide: true),
              ],
            ),
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
    return SizedBox(
      width: wide ? 150 : 96,
      child: Padding(
        padding: EdgeInsets.only(left: wide ? 16 : 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFFCBEFEB), fontSize: 10, fontWeight: FontWeight.w900)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, margin: const EdgeInsets.only(right: 16), color: Colors.white24);
  }
}

class _AlertStrip extends StatelessWidget {
  const _AlertStrip({required this.alerts});

  final List<_AlertItem> alerts;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) => _AnimatedAlert(item: alerts[index], delay: index),
      ),
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
  tween: Tween(begin: 0.95, end: 1),
  duration: const Duration(milliseconds: 400),
  builder: (context, value, child) {
    return Transform.scale(
      scale: value,
      child: child,
    );
  },
  child: Container(
        width: 216,
        padding: const EdgeInsets.all(12),
        decoration: _panelDecoration(),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: item.color.withValues(alpha: .12), shape: BoxShape.circle),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                  Text(item.detail, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF60706E), fontSize: 11, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartnerPanel extends StatelessWidget {
  const _PartnerPanel({required this.partners});

  final List<_DeliveryPartner> partners;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Active Delivery\nPartners',
                    style: TextStyle(color: Color(0xFF006B68), fontWeight: FontWeight.w900, fontSize: 21, height: 1.35),
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: _AdminDeliveryPanelState._teal,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(58, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('All\nZones', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, height: 1.05)),
                ),
                IconButton(onPressed: () {}, tooltip: 'Filter partners', icon: const Icon(Icons.filter_list_rounded, color: Color(0xFF60706E))),
              ],
            ),
          ),
          const Divider(height: 1, color: _AdminDeliveryPanelState._line),
          ...partners.map((partner) => _PartnerRow(partner: partner)),
        ],
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

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 4), bottom: const BorderSide(color: _AdminDeliveryPanelState._line)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: _AdminDeliveryPanelState._mint,
            child: Text(partner.initials, style: const TextStyle(color: _AdminDeliveryPanelState._teal, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(partner.name, style: const TextStyle(color: _AdminDeliveryPanelState._ink, fontWeight: FontWeight.w900, fontSize: 16)),
                Text('${partner.zone} • ${partner.vehicle}', style: const TextStyle(color: Color(0xFF344341), fontSize: 10, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Icon(Icons.star_rounded, color: _AdminDeliveryPanelState._teal, size: 15),
          const SizedBox(width: 2),
          Text(partner.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(width: 14),
          SizedBox(
            width: 52,
            child: Row(
              children: [
                Icon(Icons.circle, color: color, size: 8),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    duty ? 'On\nDuty' : partner.status,
                    maxLines: 2,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, height: 1),
                  ),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, tooltip: 'Partner actions', visualDensity: VisualDensity.compact, icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF60706E), size: 20)),
        ],
      ),
    );
  }
}

class _DispatchQueue extends StatelessWidget {
  const _DispatchQueue({required this.tasks});

  final List<_DispatchTask> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF246D5E),
            padding: const EdgeInsets.fromLTRB(17, 11, 14, 10),
            child: Row(
              children: [
                const Expanded(child: Text('Dispatch Queue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(5)),
                  child: const Text('12 PENDING', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          ...tasks.map((task) => _DispatchCard(task: task)),
        ],
      ),
    );
  }
}

class _DispatchCard extends StatelessWidget {
  const _DispatchCard({required this.task});

  final _DispatchTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 14, 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _AdminDeliveryPanelState._line))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 41,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F0EF),
              border: Border.all(color: _AdminDeliveryPanelState._line),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(task.minutes, style: const TextStyle(color: _AdminDeliveryPanelState._teal, fontSize: 12, fontWeight: FontWeight.w900)),
                const Text('MIN', style: TextStyle(color: _AdminDeliveryPanelState._teal, fontSize: 9, fontWeight: FontWeight.w900)),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: task.tone.withValues(alpha: .16), borderRadius: BorderRadius.circular(10)),
                      child: Text(task.priority, style: TextStyle(color: task.tone, fontSize: 10, fontWeight: FontWeight.w900)),
                    ),
                    const Spacer(),
                    Text(task.orderId, style: const TextStyle(color: Color(0xFF3E4A48), fontSize: 10, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 9),
                Text(task.title, style: const TextStyle(color: _AdminDeliveryPanelState._ink, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(task.subtitle, style: const TextStyle(color: Color(0xFF667370), fontSize: 11, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: _AdminDeliveryPanelState._teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                          minimumSize: const Size(0, 34),
                        ),
                        child: const Text('Assign', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 9),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF667370),
                        minimumSize: const Size(42, 34),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: const Icon(Icons.map_outlined, size: 20),
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

class _LiveHeatmap extends StatelessWidget {
  const _LiveHeatmap({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _panelDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: _AdminDeliveryPanelState._teal),
              const SizedBox(width: 4),
              const Expanded(child: Text('Live Zone Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _AdminDeliveryPanelState._ink))),
              TextButton(onPressed: () {}, child: const Text('Fullscreen')),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.78,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: CustomPaint(
                painter: _MapPainter(animation),
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    return Stack(
                      children: [
                        Positioned(
                          right: 8,
                          top: 10,
                          child: Transform.scale(
                            scale: .92 + animation.value * .08,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, color: Color(0xFFC91F28), size: 9),
                                  SizedBox(width: 4),
                                  Text('High Demand', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _MapPainter extends CustomPainter {
  const _MapPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF090D0F), Color(0xFF252A2D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bg);

    final road = Paint()
      ..color = Colors.white.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var i = -3; i < 13; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x + size.width * .5, size.height), road);
      canvas.drawLine(Offset(0, size.height * i / 10), Offset(size.width, size.height * (i + 3) / 10), road);
    }

    final highway = Paint()
      ..color = Colors.white.withValues(alpha: .28)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(size.width * .08, size.height)
      ..cubicTo(size.width * .32, size.height * .82, size.width * .4, size.height * .44, size.width * .68, 0);
    canvas.drawPath(path, highway);

    final heat = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFFFFF).withValues(alpha: .42 + animation.value * .2),
          const Color(0xFFE9F4F2).withValues(alpha: .22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(size.width * .58, size.height * .42), radius: size.width * .38));
    canvas.drawCircle(Offset(size.width * .58, size.height * .42), size.width * .38, heat);
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.animation != animation;
}

class _AnimatedIn extends StatelessWidget {
  const _AnimatedIn({required this.animation, required this.index, required this.child});

  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval((index * .12).clamp(0, .72), 1, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .08), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

BoxDecoration _panelDecoration() {
  return BoxDecoration(
    color: Colors.white,
    border: Border.all(color: _AdminDeliveryPanelState._line),
    borderRadius: BorderRadius.circular(10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: .04),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class _DeliveryPartner {
  const _DeliveryPartner(this.initials, this.name, this.zone, this.vehicle, this.status, this.rating);

  final String initials;
  final String name;
  final String zone;
  final String vehicle;
  final String status;
  final double rating;
}

class _DispatchTask {
  const _DispatchTask({
    required this.minutes,
    required this.priority,
    required this.orderId,
    required this.title,
    required this.subtitle,
    required this.tone,
  });

  final String minutes;
  final String priority;
  final String orderId;
  final String title;
  final String subtitle;
  final Color tone;
}

class _AlertItem {
  const _AlertItem(this.icon, this.title, this.detail, this.color);

  final IconData icon;
  final String title;
  final String detail;
  final Color color;
}
