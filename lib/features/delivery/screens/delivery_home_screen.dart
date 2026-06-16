import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/delivery_provider.dart';
import 'active_order_screen.dart';
import 'delivery_history_screen.dart';
import 'delivery_profile_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF7F7F7);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF888888);
const _kGreen = Color(0xFF22C55E);

class DeliveryHomeScreen extends StatefulWidget {
  const DeliveryHomeScreen({super.key});
  static const routeName = '/delivery';

  @override
  State<DeliveryHomeScreen> createState() => _DeliveryHomeScreenState();
}

class _DeliveryHomeScreenState extends State<DeliveryHomeScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DeliveryProvider>().loadDashboard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeliveryProvider>();
    final person = provider.deliveryPerson;
    final canSeeRequests = provider.online && (person?.active ?? false);

    return Scaffold(
      backgroundColor: _kBg,
      // ── Top App Bar ────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(Icons.menu_rounded, color: _kOrange, size: 26),
        ),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Delivery ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kOrange,
                ),
              ),
              TextSpan(
                text: 'Pro',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _kTextDark,
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Online badge
          if (provider.online)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'ACTIVE NOW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _kOrange,
                ),
              ),
            ),
          const SizedBox(width: 10),
          // Notification bell
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_none_rounded,
                    color: _kTextDark, size: 22),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _kOrange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ── Body ──────────────────────────────────────────────────────────
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // ── Profile card ─────────────────────────────────────────────
          _ProfileCard(
            name: person?.name ?? 'Delivery Partner',
            deliveryId: person?.id ?? '—',
            imageUrl: person?.avatarUrl ?? '',
            online: provider.online,
            onToggle: (v) {
              HapticFeedback.lightImpact();
              v ? provider.goOnline() : provider.goOffline();
            },
          ),

          const SizedBox(height: 16),

          // ── Metric cards ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: Icons.delivery_dining_rounded,
                  iconBg: const Color(0xFFFFF0EB),
                  iconColor: _kOrange,
                  label: 'ORDERS COMPLETED',
                  value: '${person?.completedOrders ?? 0}',
                  tag: 'Today',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  icon: Icons.account_balance_wallet_rounded,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF6366F1),
                  label: 'EARNINGS EARNED',
                  value:
                      '\$${person?.todayEarnings.toStringAsFixed(2) ?? '0.00'}',
                  tag: 'Today',
                  largeValue: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── New Requests ──────────────────────────────────────────────
          if (canSeeRequests) ...[
            Row(
              children: [
                const Text(
                  'New Requests',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(width: 10),
                if (provider.pendingRequests.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kOrangeLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${provider.pendingRequests.length} Nearby',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kOrange,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: _kOrange,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'View All',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (provider.pendingRequests.isEmpty)
              _EmptyState(
                icon: Icons.inbox_rounded,
                message: 'No new requests right now',
              )
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.pendingRequests.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final order = provider.pendingRequests[i];
                    return SizedBox(
                      width: MediaQuery.of(context).size.width - 64,
                      child: _NewRequestCard(
                        order: order,
                        onAccept: () {
                          HapticFeedback.mediumImpact();
                          provider.acceptOrder(order);
                        },
                        onReject: () => provider.rejectOrder(order),
                      ),
                    );
                  },
                ),
              ),
          ] else ...[
            const _EmptyState(
              icon: Icons.lock_outline_rounded,
              message: 'Request cards are hidden until you go active',
            ),
          ],

          const SizedBox(height: 24),

          // ── Active Order ──────────────────────────────────────────────
          const Text(
            'Active Order',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 12),
          if (provider.activeOrder == null)
            const _EmptyState(
              icon: Icons.local_shipping_outlined,
              message: 'No active order yet',
            )
          else
            GestureDetector(
              onTap: () => Navigator.of(context)
                  .pushNamed(ActiveOrderScreen.routeName),
              child: _ActiveOrderCard(order: provider.activeOrder!),
            ),
          const SizedBox(height: 24),
        ],
      ),

      // ── Bottom Nav ────────────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) {
            Navigator.of(context)
                .pushNamed(DeliveryHistoryScreen.routeName);
          }
          if (i == 3) {
            Navigator.of(context)
                .pushNamed(DeliveryProfileScreen.routeName);
          }
        },
      ),
    );
  }
}

// ─── Profile Card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.name,
    required this.deliveryId,
    required this.imageUrl,
    required this.online,
    required this.onToggle,
  });

  final String name;
  final String deliveryId;
  final String imageUrl;
  final bool online;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kOrange, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageUrl.startsWith('http')
                      ? Image.network(imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _AvatarFallback())
                      : const _AvatarFallback(),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: online ? _kGreen : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ID: #$deliveryId',
            style: const TextStyle(
              fontSize: 13,
              color: _kTextMid,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Duty status toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Duty Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                Row(
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        online ? 'ONLINE' : 'OFFLINE',
                        key: ValueKey(online),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: online ? _kOrange : _kTextMid,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch.adaptive(
                        value: online,
                        onChanged: onToggle,
                        activeColor: _kOrange,
                        activeTrackColor:
                            _kOrange.withValues(alpha: 0.25),
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

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kOrangeLight,
      child: const Icon(Icons.person_rounded, size: 44, color: _kOrange),
    );
  }
}

// ─── Metric Card ──────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.tag,
    this.largeValue = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String tag;
  final bool largeValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const Spacer(),
              Text(
                tag,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextMid,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: largeValue ? 24 : 28,
              fontWeight: FontWeight.w900,
              color: _kOrange,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _kTextMid,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── New Request Card ─────────────────────────────────────────────────────────

class _NewRequestCard extends StatefulWidget {
  const _NewRequestCard({
    required this.order,
    required this.onAccept,
    required this.onReject,
  });

  final dynamic order;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  State<_NewRequestCard> createState() => _NewRequestCardState();
}

class _NewRequestCardState extends State<_NewRequestCard> {

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: restaurant + timer ───────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: _kOrange, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(widget.order.customerName, fallback: 'Customer'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      '${_itemCount(widget.order)} items • ${_text(widget.order.customerArea, fallback: 'Unknown area')}',
                      style: const TextStyle(fontSize: 12, color: _kTextMid),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Pickup ────────────────────────────────────────────────────
          _RouteRow(
            icon: Icons.location_on_rounded,
            iconColor: _kOrange,
            label: 'Pickup:',
            line1: _text(widget.order.customerAddress, fallback: '—'),
            line2: _text(widget.order.customerArea),
          ),

          const SizedBox(height: 16),

          // ── Price + Accept ────────────────────────────────────────────
          Row(
            children: [
              Text(
                '₹${_amount(widget.order).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _kOrange,
                ),
              ),
              const Spacer(),
              // Accept button
              _SpringButton(
                onTap: widget.onAccept,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF26522), Color(0xFFE8401A)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ACCEPT REQUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),

        ],
      ),
    );
  }
}

String _text(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

int _itemCount(dynamic order) {
  try {
    return (order.itemCount as int?) ?? 0;
  } catch (_) {
    return 0;
  }
}

double _amount(dynamic order) {
  try {
    final value = order.totalAmount;
    if (value is num) return value.toDouble();
  } catch (_) {}
  try {
    final value = order.earnings;
    if (value is num) return value.toDouble();
  } catch (_) {}
  return 0;
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.line1,
    required this.line2,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String line1;
  final String line2;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                TextSpan(
                  text: line1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kTextDark,
                  ),
                ),
                if (line2.isNotEmpty)
                  TextSpan(
                    text: '\n$line2',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextMid,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Active Order Card ────────────────────────────────────────────────────────

class _ActiveOrderCard extends StatelessWidget {
  const _ActiveOrderCard({required this.order});
  final dynamic order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border(left: BorderSide(color: _kOrange, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kOrangeLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'ACTIVE ORDER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: _kOrange,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kOrangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delivery_dining_rounded,
                      color: _kOrange, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              _text(order.customerName, fallback: 'Customer Name'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            _detailRow('Customer phone', _text(order.customerPhone, fallback: '—')),
            _detailRow('Customer address', _text(order.customerAddress, fallback: '—')),
            _detailRow('Customer area', _text(order.customerArea, fallback: '—')),
            _detailRow('Payment method', _text(order.paymentType, fallback: '—')),
            _detailRow(
              'Total amount',
              '₹${_amount(order).toStringAsFixed(2)}',
              valueColor: _kOrange,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _detailRow(String label, String value, {Color valueColor = _kTextDark}) {
  return Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _kTextMid,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActiveOrderStat extends StatelessWidget {
  const _ActiveOrderStat({
    required this.label,
    required this.value,
    this.valueColor = _kTextDark,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _kTextMid,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─── Map Grid Painter ─────────────────────────────────────────────────────────

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.grid_view_rounded, 'Home'),
      (Icons.history_rounded, 'History'),
      (Icons.account_balance_wallet_rounded, 'Earnings'),
      (Icons.person_rounded, 'Profile'),
    ];

    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? _kOrange : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      item.$1,
                      size: 22,
                      color: selected ? Colors.white : _kTextMid,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.$2,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? _kOrange : _kTextMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color(0xFFDDDDDD)),
          const SizedBox(height: 10),
          Text(message,
              style: const TextStyle(color: _kTextMid, fontSize: 13)),
        ],
      ),
    );
  }
}

// ─── Spring Button ────────────────────────────────────────────────────────────

class _SpringButton extends StatefulWidget {
  const _SpringButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _s =
      Tween<double>(begin: 1.0, end: 0.93).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s, child: widget.child),
    );
  }
}
