import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/toast_widget.dart';
import 'payment_screen.dart';
import 'order_success_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);
const _kBorder = Color(0xFFE8E8E8);

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedAddressId;
  bool _initialLoadDone = false;
  bool _processingCod = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<AppState>().loadAddresses();
      if (!mounted) return;
      final state = context.read<AppState>();
      _selectedAddressId = state.selectedAddress?.id;
      if (mounted) setState(() {});
    });
  }

  AddressModel? _resolveAddress(AppState state) {
    if (state.savedAddresses.isEmpty) return null;
    final id = _selectedAddressId ?? state.selectedAddress?.id;
    return state.savedAddresses.firstWhere(
      (a) => a.id == id,
      orElse: () => state.savedAddresses.first,
    );
  }

  // ── COD order ─────────────────────────────────────────────────────────────
  Future<void> _placeCodOrder(
    AppState state,
    AddressModel selectedAddress,
  ) async {
    setState(() => _processingCod = true);
    try {
      await state.checkout(
        address: selectedAddress.fullAddress,
        paymentMethod: 'cod',
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      showToast(context, '✅ COD order placed!');
      Navigator.pushReplacementNamed(context, OrderSuccessScreen.routeName);
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _processingCod = false);
    }
  }

  // ── Stripe — set address then navigate ─────────────────────────────────────
  Future<void> _goToStripe(
    AppState state,
    AddressModel selectedAddress,
  ) async {
    state.selectedAddress = selectedAddress;
    state.notifyListeners();
    if (!mounted) return;
    Navigator.pushNamed(context, PaymentScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final addresses = state.savedAddresses;
            final selectedAddress = _resolveAddress(state);
            final canOrder =
                addresses.isNotEmpty && state.cart.isNotEmpty && selectedAddress != null;

            return Column(
              children: [
                _TopBar(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ── Hero title ────────────────────────────────────
                        const Text(
                          'Confirm delivery\nand payment',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: _kTextDark,
                            height: 1.1,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose a delivery address and your preferred payment method.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black.withValues(alpha: 0.52),
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Addresses ─────────────────────────────────────
                        const _SectionLabel('📍  Delivery address'),
                        const SizedBox(height: 12),
                        if (addresses.isEmpty)
                          const _InfoCard(
                            icon: Icons.location_off_rounded,
                            title: 'No saved addresses',
                            subtitle:
                                'Add an address from your profile to continue.',
                          )
                        else
                          SizedBox(
                            height: 172,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: addresses.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (_, i) {
                                final addr = addresses[i];
                                final sel = _selectedAddressId == addr.id ||
                                    (_selectedAddressId == null &&
                                        state.selectedAddress?.id == addr.id);
                                return _AddressCard(
                                  data: addr,
                                  selected: sel,
                                  onTap: () => setState(
                                    () => _selectedAddressId = addr.id,
                                  ),
                                );
                              },
                            ),
                          ),

                        const SizedBox(height: 24),

                        // ── Order summary ─────────────────────────────────
                        const _SectionLabel('🧾  Order summary'),
                        const SizedBox(height: 12),
                        _SummaryCard(
                          subtotal: state.subtotal,
                          deliveryFee: state.deliveryFee,
                          total: state.total,
                        ),

                        const SizedBox(height: 24),

                        // ── Payment methods ───────────────────────────────
                        const _SectionLabel('💳  Payment method'),
                        const SizedBox(height: 12),

                        // COD button
                        _ActionButton(
                          label: 'Place COD Order',
                          icon: Icons.money_rounded,
                          loading: _processingCod,
                          enabled: canOrder,
                          onTap: () =>
                              _placeCodOrder(state, selectedAddress!),
                        ),

                        const SizedBox(height: 12),

                        // Stripe button
                        _StripeButton(
                          enabled: canOrder,
                          onTap: () => _goToStripe(state, selectedAddress!),
                        ),

                        const SizedBox(height: 16),

                        // Delivery address reminder
                        if (selectedAddress != null)
                          _DeliveryAddressChip(
                            address: selectedAddress.fullAddress,
                          )
                        else
                          const _InfoCard(
                            icon: Icons.info_outline_rounded,
                            title: 'Select an address',
                            subtitle:
                                'Tap a saved address above to continue.',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  size: 26, color: _kTextDark),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Checkout',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: _kTextDark,
      ),
    );
  }
}

// ─── Address Card ─────────────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final AddressModel data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? _kOrange : _kBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? _kOrange.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? _kOrange : _kOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: selected ? Colors.white : _kOrange,
                  ),
                ),
                const Spacer(),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded,
                      color: _kOrange, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              data.line1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              data.shortAddress,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _kTextMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
  });

  final double subtotal;
  final double deliveryFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Subtotal', value: subtotal),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Delivery fee', value: deliveryFee),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(
              height: 1,
              color: Colors.grey.shade100,
            ),
          ),
          _SummaryRow(label: 'Total', value: total, bold: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 13,
            color: bold ? _kTextDark : const Color(0xFF666666),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          'Rs ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: bold ? 17 : 13,
            color: bold ? _kOrange : _kTextDark,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Action Button (COD) ──────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !widget.loading;

    return GestureDetector(
      onTapDown: active ? (_) => _c.forward() : null,
      onTapUp: active
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFFF26522), Color(0xFFE8401A)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: active ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(999),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _kOrange.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(widget.icon,
                          size: 18,
                          color: active ? Colors.white : Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: active ? Colors.white : Colors.grey,
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

// ─── Stripe Button ───────────────────────────────────────────────────────────

const _kStripe = Color(0xFF635BFF);

class _StripeButton extends StatefulWidget {
  const _StripeButton({required this.enabled, required this.onTap});
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_StripeButton> createState() => _StripeButtonState();
}

class _StripeButtonState extends State<_StripeButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.96).animate(
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
      onTapDown: widget.enabled ? (_) => _c.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _c.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? const LinearGradient(
                    colors: [Color(0xFF7B73FF), Color(0xFF5851DB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.enabled ? null : const Color(0xFFE0E0E0),
            borderRadius: BorderRadius.circular(999),
            boxShadow: widget.enabled
                ? [
                    BoxShadow(
                      color: _kStripe.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: widget.enabled ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Pay with Stripe',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: widget.enabled ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Delivery address chip ────────────────────────────────────────────────────

class _DeliveryAddressChip extends StatelessWidget {
  const _DeliveryAddressChip({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded,
              size: 16, color: _kOrange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Delivering to: $address',
              style: const TextStyle(
                fontSize: 12.5,
                color: _kOrange,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kOrangeLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _kOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _kTextDark,
                    )),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
