import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../providers/app_state.dart';
import '../user/user_home_screen.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  static const routeName = '/order-success';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final latest = state.orders.isEmpty ? null : state.orders.first;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),

                  // Delivery illustration circle
                  Container(
                    width: 148,
                    height: 148,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE8541A).withValues(alpha: 0.12),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: latest != null && latest.products.isNotEmpty
                            ? _OrderImage(imageUrl: latest.products.first.imageUrl)
                            : Image.asset(
                                'assets/images/delivery_boy.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.delivery_dining,
                                  size: 72,
                                  color: Color(0xFFE8541A),
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Title
                  const Text(
                    'Order Confirmed',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your order was placed successfully',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Product card
                  if (latest != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF0F0F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEEEEEE)),
                            ),
                            child: latest != null && latest.products.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: _OrderThumb(
                                      imageUrl: latest.products.first.imageUrl,
                                    ),
                                  )
                                : const Icon(
                                    Icons.shopping_bag_outlined,
                                    color: Color(0xFF999999),
                                    size: 24,
                                  ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  latest.products.isNotEmpty
                                      ? latest.products.first.name
                                      : 'Your Order',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  latest.products.isNotEmpty
                                      ? latest.products.first.category
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFAAAAAA),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs ${latest.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Order Summary section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Order ID',
                          value: latest?.id ?? '—',
                        ),
                        const SizedBox(height: 14),
                        _SummaryRow(
                          label: 'Shipping Address',
                          value: latest?.address ?? '—',
                        ),
                        const SizedBox(height: 14),
                        _SummaryRow(
                          label: 'Tracking ID',
                          value: latest?.id ?? '—',
                        ),
                        const SizedBox(height: 14),
                        _SummaryRow(
                          label: 'Estimated Delivery Date',
                          value: _estimatedDelivery(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Return to Home button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        UserHomeScreen.routeName,
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8541A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: const Color(0xFFE8541A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Return to Home',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Confirmation note
                  const Text(
                    'Your order has been confirmed successfully',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF2EAA5A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _estimatedDelivery() {
    final delivery = DateTime.now().add(const Duration(hours: 1));
    final month = delivery.month.toString().padLeft(2, '0');
    final day = delivery.day.toString().padLeft(2, '0');
    final year = delivery.year.toString().substring(2);
    final hour = delivery.hour.toString().padLeft(2, '0');
    final minute = delivery.minute.toString().padLeft(2, '0');
    return '$month/$day/$year, $hour:${minute}pm';
  }
}

// ─── Summary Row ─────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF999999),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderImage extends StatelessWidget {
  const _OrderImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(imageUrl);
    if (normalized.startsWith('http')) {
      return Image.network(
        normalized,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.delivery_dining,
          size: 72,
          color: Color(0xFFE8541A),
        ),
      );
    }
    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.delivery_dining,
          size: 72,
          color: Color(0xFFE8541A),
        ),
      );
    }
    return const Icon(
      Icons.delivery_dining,
      size: 72,
      color: Color(0xFFE8541A),
    );
  }
}

class _OrderThumb extends StatelessWidget {
  const _OrderThumb({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(imageUrl);
    if (normalized.startsWith('http')) {
      return Image.network(normalized, fit: BoxFit.cover, width: 48, height: 48);
    }
    if (normalized.startsWith('assets/')) {
      return Image.asset(normalized, fit: BoxFit.cover, width: 48, height: 48);
    }
    return const ColoredBox(
      color: Color(0xFFF1F1F1),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Color(0xFF999999), size: 18),
      ),
    );
  }
}
