import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/delivery_order_model.dart';
import '../providers/delivery_provider.dart';
import 'delivery_home_screen.dart';
import 'delivery_history_screen.dart';
import 'delivery_profile_screen.dart';
import '../../../widgets/toast_widget.dart';

class ActiveOrderScreen extends StatefulWidget {
  const ActiveOrderScreen({super.key});
  static const routeName = '/delivery/active-order';

  @override
  State<ActiveOrderScreen> createState() => _ActiveOrderScreenState();
}

class _ActiveOrderScreenState extends State<ActiveOrderScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _otpError;
  bool _otpVerified = false;
  bool _markingDelivered = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp(DeliveryOrderModel order) {
    final entered = _otpController.text.trim();
    if (entered.isEmpty) {
      setState(() {
        _otpVerified = false;
        _otpError = 'Enter OTP first';
      });
      return;
    }

    final expected = order.deliveryOtpDisplay;
    if (entered == expected) {
      setState(() {
        _otpVerified = true;
        _otpError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP matched successfully')),
      );
      return;
    }

    setState(() {
      _otpVerified = false;
      _otpError = 'OTP does not match';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP does not match')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final provider = context.watch<DeliveryProvider>();
    final order = provider.activeOrder;
    if (order == null) {
      return Scaffold(
        backgroundColor: Color(0xFFF6F7FB),
        body: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF0F2F5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      size: 44,
                      color: Color(0xFFE8541A),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'There is no active orders',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'New delivery requests will appear here once assigned.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final status = _statusLabel(order.status);
    final isCod = order.isCod;
    final canEnterOtp = order.status == DeliveryOrderStatus.pickedUp ||
        order.status == DeliveryOrderStatus.outForDelivery ||
        order.status == DeliveryOrderStatus.delivered;
    final pickupFlowColor = order.status == DeliveryOrderStatus.pickedUp ||
            order.status == DeliveryOrderStatus.outForDelivery ||
            order.status == DeliveryOrderStatus.delivered
        ? const Color(0xFFE8541A)
        : const Color(0xFFD1D5DB);
    final otpMatches = _otpVerified &&
        _otpController.text.trim() == order.deliveryOtpDisplay;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8541A), Color(0xFFFF7A2F)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          tooltip: 'Back',
                        ),
                        const Icon(Icons.delivery_dining_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Active Order',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ),
                        _statusPill(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Track and complete the assigned delivery.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.receipt_long_rounded,
                            label: 'Order ID',
                            value: order.displayOrderId,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStat(
                            icon: Icons.storefront_rounded,
                            label: 'Store',
                            value: order.vendorStoreName?.trim().isNotEmpty == true
                                ? order.vendorStoreName!.trim()
                                : 'Vendor store',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 24 + bottomInset),
                child: Column(
                  children: [
                    _DashboardCard(
                      title: 'Vendor Details',
                      child: Column(
                        children: [
                          _infoRow(
                            'Store name',
                            order.vendorStoreName?.trim().isNotEmpty == true
                                ? order.vendorStoreName!.trim()
                                : '—',
                          ),
                          _infoRow(
                            'Pickup address',
                            order.vendorPickupAddress?.trim().isNotEmpty == true
                                ? order.vendorPickupAddress!.trim()
                                : (order.vendorAddress?.trim().isNotEmpty == true
                                    ? order.vendorAddress!.trim()
                                    : '—'),
                          ),
                          _infoRow(
                            'Pickup city',
                            order.vendorCity?.trim().isNotEmpty == true
                                ? order.vendorCity!.trim()
                                : '—',
                          ),
                          _infoRow(
                            'Pickup pincode',
                            order.vendorPincode?.trim().isNotEmpty == true
                                ? order.vendorPincode!.trim()
                                : '—',
                          ),
                          _infoRow(
                            'Store phone',
                            order.vendorPhone?.trim().isNotEmpty == true
                                ? order.vendorPhone!.trim()
                                : '—',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardCard(
                      title: 'Order Summary',
                      child: Column(
                        children: [
                          _infoRow('Customer name', order.customerName),
                          _infoRow('Customer phone', order.customerPhone),
                          _infoRow('Customer address', order.customerAddress),
                          _infoRow(
                            'Customer street',
                            order.customerLine1?.trim().isNotEmpty == true
                                ? order.customerLine1!.trim()
                                : '—',
                          ),
                          _infoRow(
                            'Customer city',
                            order.customerCity?.trim().isNotEmpty == true
                                ? order.customerCity!.trim()
                                : '—',
                          ),
                          _infoRow(
                            'Customer pincode',
                            order.customerPincode?.trim().isNotEmpty == true
                                ? order.customerPincode!.trim()
                                : '—',
                          ),
                          _infoRow('Customer area', order.customerArea),
                          _infoRow('Payment method', order.paymentType),
                          if (isCod)
                            _infoRow(
                              'COD amount',
                              '₹${order.codAmount?.toStringAsFixed(2) ?? order.totalAmount.toStringAsFixed(2)}',
                            ),
                          _infoRow('Total amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
                          _infoRow('Created at', _formatDate(order.createdAt)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardCard(
                      title: 'Ordered Items',
                      child: order.items.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Text('No item details available'),
                            )
                          : Column(
                              children: order.items
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _OrderedItemTile(item: item),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    const SizedBox(height: 14),
                    _DashboardCard(
                      title: 'Delivery Actions',
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF171923),
                              const Color(0xFF1F2937),
                              const Color(0xFF0F172A),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0x33FFFFFF)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.14),
                              blurRadius: 24,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            TextField(
                              controller: _otpController,
                              enabled: canEnterOtp,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: canEnterOtp
                                    ? 'Enter OTP to unlock delivery'
                                    : 'OTP unlocks after pickup',
                                hintStyle: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.08),
                                errorText: _otpError,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFFFFA142)),
                                ),
                              ),
                              onChanged: (value) {
                                if (!canEnterOtp) return;
                                setState(() {
                                  _otpError = null;
                                  _otpVerified = false;
                                });
                              },
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: canEnterOtp ? () => _verifyOtp(order) : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFFFFA142)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Verify OTP',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Color(0xFFFF8A3D), Color(0xFFE8541A)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE8541A).withValues(alpha: 0.25),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.bolt_rounded,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Control Center',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        'Fast actions for delivery execution',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.68),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Flow',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _ActionTile(
                              icon: Icons.map_outlined,
                              title: 'Open Google Maps',
                              subtitle: 'Navigate to customer address',
                              accent: const Color(0xFFFF8A3D),
                              onTap: () => _openMap(order.customerAddress),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.call_outlined,
                              title: 'Call customer',
                              subtitle: 'Connect instantly with the customer',
                              accent: const Color(0xFFFFA142),
                              onTap: () => _call(order.customerPhone),
                            ),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Mark Picked Up',
                              subtitle: 'Update when package leaves the shed',
                              accent: const Color(0xFFFFB366),
                              onTap: provider.markPickedUp,
                            ),
                            const SizedBox(height: 6),
                            _PickupToOtpArrow(color: pickupFlowColor),
                            const SizedBox(height: 6),
                            const SizedBox(height: 10),
                            _ActionTile(
                              icon: Icons.local_shipping_rounded,
                              title: 'Mark Delivered',
                              subtitle: 'Complete the delivery flow',
                              accent: const Color(0xFFE8541A),
                              isPrimary: true,
                              onTap: otpMatches && !_markingDelivered
                                  ? () async {
                                      setState(() => _markingDelivered = true);
                                      final message = await provider.markDelivered(_otpController.text);
                                      if (!context.mounted) return;
                                      setState(() => _markingDelivered = false);
                                      if (message == null) {
                                        showToast(context, 'Order delivered successfully');
                                      } else if (message.isNotEmpty) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(content: Text(message)));
                                      }
                                    }
                                  : null,
                              disabled: !otpMatches,
                              loading: _markingDelivered,
                              disabledLabel: _markingDelivered
                                  ? 'Delivering...'
                                  : _otpVerified
                                  ? 'Ready to deliver'
                                  : 'Verify OTP first',
                              onDisabledTap: () {
                                setState(() {
                                  _otpError = 'OTP does not match';
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: 0,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              DeliveryHistoryScreen.routeName,
              (route) => route.isFirst,
            );
          } else if (i == 3) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              DeliveryProfileScreen.routeName,
              (route) => route.isFirst,
            );
          } else if (i == 0) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              DeliveryHomeScreen.routeName,
              (route) => route.isFirst,
            );
          }
        },
      ),
    );
  }

  Widget _statusPill(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(DeliveryOrderStatus status) {
    return switch (status) {
      DeliveryOrderStatus.waitingForAccept => 'Waiting',
      DeliveryOrderStatus.accepted => 'Accepted',
      DeliveryOrderStatus.pickedUp => 'Picked up',
      DeliveryOrderStatus.outForDelivery => 'Out for delivery',
      DeliveryOrderStatus.delivered => 'Delivered',
      DeliveryOrderStatus.rejected => 'Rejected',
    };
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  Future<void> _openMap(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }
}

class _PickupToOtpArrow extends StatelessWidget {
  const _PickupToOtpArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: color,
              thickness: 2,
              height: 0,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Icon(
              Icons.arrow_downward_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(
              color: color,
              thickness: 2,
              height: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F2F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF111827),
                ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

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

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: 76,
          decoration: BoxDecoration(
            color: Colors.white,
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
                          color: selected ? const Color(0xFFE8541A) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item.$1,
                          size: 22,
                          color: selected ? Colors.white : const Color(0xFF888888),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: selected ? const Color(0xFFE8541A) : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemChip extends StatelessWidget {
  const _ItemChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF0EB),
          borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFFD2C0)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8541A),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OrderedItemTile extends StatelessWidget {
  const _OrderedItemTile({required this.item});

  final DeliveryOrderItem item;

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl;
    final hasPrice = item.unitPrice > 0;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            child: Container(
              width: 72,
              height: 72,
              color: const Color(0xFFFFF0EB),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        color: Color(0xFFE8541A),
                      ),
                    )
                  : const Icon(
                      Icons.shopping_bag_outlined,
                      color: Color(0xFFE8541A),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasPrice
                        ? 'Qty: ${item.quantity}  •  ₹${item.unitPrice.toStringAsFixed(2)} each'
                        : 'Qty: ${item.quantity}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Badge(
                        label: 'Item total',
                        value: hasPrice ? '₹${item.lineTotal.toStringAsFixed(2)}' : '—',
                      ),
                      const SizedBox(width: 10),
                      _Badge(
                        label: 'Ordered',
                        value: '${item.quantity}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0EB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE8541A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.isPrimary = false,
    this.disabled = false,
    this.disabledLabel,
    this.onDisabledTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool disabled;
  final String? disabledLabel;
  final VoidCallback? onDisabledTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: disabled ? onDisabledTap : onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPrimary
                  ? [
                      accent.withValues(alpha: 0.95),
                      const Color(0xFFFF7A2F),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.04),
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isPrimary ? accent.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                      color: accent.withValues(alpha: isPrimary ? 0.34 : 0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: loading
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Stack(
                        children: [
                          Center(child: Icon(icon, color: Colors.white, size: 22)),
                          Positioned(
                            right: 3,
                            bottom: 3,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      disabled && disabledLabel != null ? disabledLabel! : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Icon(
                  loading
                      ? Icons.hourglass_top_rounded
                      : disabled
                          ? Icons.lock_rounded
                          : Icons.arrow_forward_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
