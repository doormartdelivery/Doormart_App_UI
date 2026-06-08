import 'package:flutter/material.dart';

import '../app_page.dart';

Future<void> showAdminNotificationModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AdminNotificationSheet(),
  );
}

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  static const routeName = '/admin/notifications';

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  int _selectedNav = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7FAF8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF17211B)),
          onPressed: () {},
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF0F766E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: Color(0xFF17211B)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0F766E),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _NotificationHero(),
            SizedBox(height: 16),
            _NotificationStatsList(),
            SizedBox(height: 16),
            _NotificationToolbar(),
            SizedBox(height: 12),
            _AdminNotificationList(),
            SizedBox(height: 24),
            _OverlayPreviewSection(),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNavBar(
        selectedIndex: _selectedNav,
        onTap: (i) => setState(() => _selectedNav = i),
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.inbox, 'Inbox'),
      _NavItem(Icons.radio_button_unchecked, 'Active'),
      _NavItem(Icons.flag_outlined, 'Priority'),
      _NavItem(Icons.archive_outlined, 'Archive'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final item = items[i];
            final selected = i == selectedIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: selected
                            ? const Color(0xFF0F766E)
                            : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? const Color(0xFF0F766E)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

// ── Hero ──────────────────────────────────────────────────────────────────────

class _NotificationHero extends StatelessWidget {
  const _NotificationHero();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12372A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Smart Alert Hub',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Precision management for your system's heartbeat. Monitor delivery flows and stock levels.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => showAdminNotificationModal(context),
              icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
              label: const Text(
                'Quick preview',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: Colors.white54,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stats list (vertical cards) ───────────────────────────────────────────────

class _NotificationStatsList extends StatelessWidget {
  const _NotificationStatsList();

  @override
  Widget build(BuildContext context) {
    final unread =
        _mockAdminNotifications.where((item) => !item.isRead).length;
    final critical = _mockAdminNotifications
        .where((item) => item.severity == _NotificationSeverity.critical)
        .length;
    final delivery = _mockAdminNotifications
        .where((item) => item.category == 'Delivery')
        .length;

    return Column(
      children: [
        _StatCard(
          icon: Icons.mark_email_unread_outlined,
          iconColor: const Color(0xFF0F766E),
          label: 'UNREAD',
          value: unread.toString().padLeft(2, '0'),
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.priority_high,
          iconColor: const Color(0xFFDC2626),
          label: 'CRITICAL',
          value: critical.toString().padLeft(2, '0'),
        ),
        const SizedBox(height: 10),
        _StatCard(
          icon: Icons.delivery_dining,
          iconColor: const Color(0xFFB45309),
          label: 'DELIVERY ISSUES',
          value: delivery.toString().padLeft(2, '0'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: const Color(0xFF17211B),
                          fontWeight: FontWeight.w900,
                          height: 1.1,
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

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _NotificationToolbar extends StatelessWidget {
  const _NotificationToolbar();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: const [
          _FilterChip(label: 'All', selected: true),
          SizedBox(width: 8),
          _FilterChip(label: 'Critical'),
          SizedBox(width: 8),
          _FilterChip(label: 'Stock'),
          SizedBox(width: 8),
          _FilterChip(label: 'SLA'),
        ],
      ),
    );
  }
}

// ── Notification list ─────────────────────────────────────────────────────────

class _AdminNotificationList extends StatelessWidget {
  const _AdminNotificationList({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _mockAdminNotifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _AdminNotificationTile(
          notification: _mockAdminNotifications[index],
        );
      },
    );
  }
}

class _AdminNotificationTile extends StatelessWidget {
  const _AdminNotificationTile({required this.notification});

  final _AdminNotification notification;

  @override
  Widget build(BuildContext context) {
    final tone = notification.tone;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: tone.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(notification.icon, color: tone, size: 22),
                    ),
                    if (!notification.isRead)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: tone,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: const Color(0xFF17211B),
                                    fontWeight: FontWeight.w800,
                                    height: 1.3,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            notification.timeLabel,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.body,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF64748B),
                                  height: 1.45,
                                ),
                      ),
                     const SizedBox(height: 10),

Align(
  alignment: Alignment.centerRight,
  child: Padding(
    padding: const EdgeInsets.all(12.0), // Increase outer padding
    child: SizedBox(
      width: 140, // Increase width
      height: 30, // Increase height
      child: _ActionButton(
        label: notification.actionLabel,
        tone: tone,
        severity: notification.severity,
      ),
    ),
  ),
),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.tone,
    required this.severity,
  });

  final String label;
  final Color tone;
  final _NotificationSeverity severity;

  @override
  Widget build(BuildContext context) {
    final isCritical = severity == _NotificationSeverity.critical;

    if (isCritical) {
      return FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(
          backgroundColor: tone,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 13),
          ],
        ),
      );
    }

    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: tone,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }
}

// ── Overlay Preview Section ───────────────────────────────────────────────────

class _OverlayPreviewSection extends StatelessWidget {
  const _OverlayPreviewSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERLAY PREVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        Text(
                          'Alerts',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: const Color(0xFF17211B),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0F766E),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const _OverlayAlertItem(
                    icon: Icons.error,
                    iconColor: Color(0xFFDC2626),
                    label: 'Critical Stock Alert',
                    labelColor: Color(0xFFDC2626),
                    bold: true,
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFE2E8F0)),
                  const _OverlayAlertItem(
                    icon: Icons.schedule,
                    iconColor: Color(0xFF2563EB),
                    label: 'Order #DM-1048 delayed',
                    labelColor: Color(0xFF2563EB),
                    bold: false,
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFE2E8F0)),
                  const _OverlayAlertItem(
                    icon: Icons.notifications_outlined,
                    iconColor: Color(0xFF64748B),
                    label: 'System Update Scheduled',
                    labelColor: Color(0xFF475569),
                    bold: false,
                  ),
                  const Divider(height: 1, indent: 16, color: Color(0xFFE2E8F0)),
                  const _OverlayAlertItem(
                    icon: Icons.trending_up,
                    iconColor: Color(0xFF0F766E),
                    label: 'New demand insights ready',
                    labelColor: Color(0xFF475569),
                    bold: false,
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {},
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF12372A),
                          padding:
                              const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        child: const Text('View full center'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OverlayAlertItem extends StatelessWidget {
  const _OverlayAlertItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.bold,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: labelColor,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom Sheet ──────────────────────────────────────────────────────────────

class _AdminNotificationSheet extends StatelessWidget {
  const _AdminNotificationSheet();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * 0.88, maxWidth: 760),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xFFF7FAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8D3CC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin alert model',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: const Color(0xFF17211B),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Live-looking mock alerts for store operations.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF64748B),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Flexible(child: _AdminNotificationList(compact: true)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(
                        context,
                        AdminNotificationsScreen.routeName,
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open notification center'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Filter Chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {},
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF475569),
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
      selectedColor: const Color(0xFF0F766E),
      backgroundColor: Colors.white,
      side: BorderSide(
        color:
            selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────

class _AdminNotification {
  const _AdminNotification({
    required this.title,
    required this.body,
    required this.category,
    required this.timeLabel,
    required this.actionLabel,
    required this.icon,
    required this.tone,
    required this.severity,
    required this.isRead,
  });

  final String title;
  final String body;
  final String category;
  final String timeLabel;
  final String actionLabel;
  final IconData icon;
  final Color tone;
  final _NotificationSeverity severity;
  final bool isRead;
}

enum _NotificationSeverity { critical, warning, info }

const _mockAdminNotifications = [
  _AdminNotification(
    title: 'Tomato stock is below reorder level',
    body: 'Inventory alert: Stock has fallen below 10kg threshold.',
    category: 'Stock',
    timeLabel: 'Just now',
    actionLabel: 'Reorder Now',
    icon: Icons.inventory_2,
    tone: Color(0xFFDC2626),
    severity: _NotificationSeverity.critical,
    isRead: false,
  ),
  _AdminNotification(
    title: 'Order #DM-1048 crossed SLA',
    body: 'Delivery delayed by more than 45 mins. Escalation required.',
    category: 'Order',
    timeLabel: '12m ago',
    actionLabel: 'Escalate !',
    icon: Icons.receipt_long,
    tone: Color(0xFF2563EB),
    severity: _NotificationSeverity.warning,
    isRead: false,
  ),
  _AdminNotification(
    title: 'No delivery partner near Zone 4',
    body: 'Critical gap in delivery coverage detected for active orders.',
    category: 'Delivery',
    timeLabel: '30m ago',
    actionLabel: 'Assign rider',
    icon: Icons.delivery_dining,
    tone: Color(0xFFB45309),
    severity: _NotificationSeverity.critical,
    isRead: false,
  ),
  _AdminNotification(
    title: 'Refund request needs review',
    body: 'Order #DM-9921 marked for partial refund by customer support.',
    category: 'Payment',
    timeLabel: '1h ago',
    actionLabel: 'Review Details',
    icon: Icons.payments,
    tone: Color(0xFF7C3AED),
    severity: _NotificationSeverity.warning,
    isRead: true,
  ),
  _AdminNotification(
    title: 'Banana demand spike detected',
    body: "Orders for category 'Fruit' are up 40% in the last hour.",
    category: 'Insights',
    timeLabel: '3h ago',
    actionLabel: 'View Insights',
    icon: Icons.trending_up,
    tone: Color(0xFF0F766E),
    severity: _NotificationSeverity.info,
    isRead: true,
  ),
];