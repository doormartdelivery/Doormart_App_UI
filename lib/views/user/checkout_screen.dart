import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/toast_widget.dart';
import 'add_edit_address_screen.dart';
import 'payment_screen.dart';
import 'order_success_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeDeep = Color(0xFFB83A0B);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kInk = Color(0xFF14141B);
const _kInk2 = Color(0xFF2B2B3D);
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);
const _kBorder = Color(0xFFE8E8E8);
const _kGreen = Color(0xFF16A34A);
const _kViolet = Color(0xFF6C63F0);
const _kVioletDeep = Color(0xFF3E37B5);

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
  Future<Map<String, dynamic>>? _summaryFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final state = context.read<AppState>();
      // Refresh cart products so vendor pickup coordinates are available for
      // distance-based delivery pricing.
      await state.loadCart();
      if (!mounted) return;
      await state.loadCheckoutSettings();
      if (!mounted) return;
      await state.loadAddresses();
      if (!mounted) return;
      _selectedAddressId = state.selectedAddress?.id;
      // Never render a summary calculated for a previous address or cart.
      state.checkoutSummary = null;
      _summaryFuture = state.loadCheckoutSummary(
        address: state.selectedAddress,
      );
      final summary = await _summaryFuture;
      if (!mounted) return;
      state.checkoutSummary = summary;
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

  void _selectAddress(AppState state, AddressModel address) {
    HapticFeedback.selectionClick();
    state.selectedAddress = address;
    state.checkoutSummary = null;
    final summaryFuture = state.loadCheckoutSummary(address: address);
    setState(() {
      _selectedAddressId = address.id;
      _summaryFuture = summaryFuture;
    });
  }

  // ── COD order ─────────────────────────────────────────────────────────────
  Future<void> _placeCodOrder(
    AppState state,
    AddressModel selectedAddress,
  ) async {
    setState(() => _processingCod = true);
    try {
      await state.checkout(address: selectedAddress, paymentMethod: 'cod');
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

  // ── Cashfree — set address then navigate ───────────────────────────────────
  Future<void> _goToCashfree(
    AppState state,
    AddressModel selectedAddress,
  ) async {
    state.selectedAddress = selectedAddress;
    if (!mounted) return;
    await Navigator.pushNamed(context, PaymentScreen.routeName);
  }

  Future<void> _openAddAddress({bool reselect = false}) async {
    final appState = context.read<AppState>();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditAddressScreen()),
    );
    if (result == true && mounted) {
      await appState.loadAddresses();
      if (!mounted) return;
      if (reselect) {
        final address = appState.selectedAddress;
        if (address != null) _selectAddress(appState, address);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const _AmbientBackground(),
          SafeArea(
            child: Consumer<AppState>(
              builder: (context, state, _) {
                final addresses = state.savedAddresses;
                final selectedAddress = _resolveAddress(state);
                final canOrder =
                    addresses.isNotEmpty &&
                    state.cart.isNotEmpty &&
                    selectedAddress != null;
                final vendorEntries = <String, String>{};
                for (final line in state.cart) {
                  final vendorId = line.product.vendorId.trim().isEmpty
                      ? 'main'
                      : line.product.vendorId.trim();
                  final storeName = line.product.supplierName.trim().isNotEmpty
                      ? line.product.supplierName.trim()
                      : (vendorId == 'main' ? 'Main Store' : vendorId);
                  final city = line.product.supplierCity.trim();
                  vendorEntries.putIfAbsent(
                    vendorId,
                    () => city.isNotEmpty ? '$storeName, $city' : storeName,
                  );
                }
                final vendorLabels = vendorEntries.values.toList(
                  growable: false,
                );
                final hasMultiVendorCart = vendorEntries.length > 1;

                return Column(
                  children: [
                    _TopBar(onBack: () => Navigator.pop(context)),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Hero ──────────────────────────────────────
                            const _Entrance(index: 0, child: _HeroHeader()),
                            const SizedBox(height: 28),

                            // ── Addresses ─────────────────────────────────
                            _Entrance(
                              index: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionLabel(
                                    icon: Icons.place_rounded,
                                    text: 'Delivery address',
                                  ),
                                  const SizedBox(height: 14),
                                  const _LocationTipCard(),
                                  const SizedBox(height: 14),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _GlassOutlineButton(
                                      icon: Icons.add_rounded,
                                      label: 'Add New Address',
                                      onTap: () =>
                                          _openAddAddress(reselect: true),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  if (addresses.isEmpty)
                                    _InfoCard(
                                      icon: Icons.location_off_rounded,
                                      title: 'No saved addresses',
                                      subtitle:
                                          'Add an address now to continue checkout.',
                                      actionLabel: 'Add address',
                                      onAction: () => _openAddAddress(),
                                    )
                                  else
                                    SizedBox(
                                      height: 246,
                                      child: ListView.separated(
                                        clipBehavior: Clip.none,
                                        physics: const BouncingScrollPhysics(),
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.only(
                                          top: 16,
                                          bottom: 14,
                                          right: 12,
                                        ),
                                        itemCount: addresses.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(width: 14),
                                        itemBuilder: (_, i) {
                                          final addr = addresses[i];
                                          final sel =
                                              _selectedAddressId == addr.id ||
                                              (_selectedAddressId == null &&
                                                  state.selectedAddress?.id ==
                                                      addr.id);
                                          return _AddressCard(
                                            data: addr,
                                            selected: sel,
                                            onTap: () =>
                                                _selectAddress(state, addr),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ── Order summary card ─────────────────────────
                            _Entrance(
                              index: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<Map<String, dynamic>>(
                                    future:
                                        _summaryFuture ??
                                        state.loadCheckoutSummary(
                                          address: selectedAddress,
                                        ),
                                    builder: (context, snapshot) {
                                      // Do not fall back to AppState's last
                                      // response: it may belong to the previous
                                      // address while the newly selected
                                      // address is still loading.
                                      final summary = snapshot.data;
                                      final subtotal =
                                          (summary?['subtotal'] as num?)
                                              ?.toDouble() ??
                                          state.subtotal;
                                      final localDistanceFee = state
                                          .distanceBasedDeliveryFee(
                                            selectedAddress,
                                          );
                                      final localDeliveryBreakdown = state
                                          .deliveryChargeBreakdown(
                                            selectedAddress,
                                          );
                                      final serverVendorFees =
                                          summary?['deliveryFeesByVendor']
                                              as Map<String, dynamic>?;
                                      final serverVendorDistances =
                                          summary?['deliveryDistancesByVendor']
                                              as Map<String, dynamic>?;
                                      final serverRatePerKm =
                                          (summary?['deliveryRatePerKm']
                                                  as num?)
                                              ?.toDouble();
                                      final effectiveDeliveryBreakdown =
                                          serverVendorFees == null
                                          ? localDeliveryBreakdown
                                          : serverVendorFees.entries.map((
                                              serverEntry,
                                            ) {
                                              final localEntry =
                                                  localDeliveryBreakdown
                                                      .where(
                                                        (entry) =>
                                                            entry.vendorId ==
                                                            serverEntry.key,
                                                      )
                                                      .firstOrNull;
                                              final feeValue =
                                                  serverEntry.value is Map
                                                  ? (serverEntry.value['fee']
                                                            as num?)
                                                        ?.toDouble()
                                                  : (serverEntry.value as num?)
                                                        ?.toDouble();
                                              final distanceValue =
                                                  (serverVendorDistances?[serverEntry
                                                              .key]
                                                          as num?)
                                                      ?.toDouble() ??
                                                  localEntry?.distanceKm;
                                              return DeliveryChargeBreakdown(
                                                vendorId: serverEntry.key,
                                                storeName:
                                                    localEntry?.storeName ??
                                                    _storeNameForVendor(
                                                      state.cart,
                                                      serverEntry.key,
                                                    ),
                                                distanceKm: distanceValue ?? 0,
                                                fee:
                                                    feeValue ??
                                                    localEntry?.fee ??
                                                    0,
                                              );
                                            }).toList();
                                      final deliveryDistance = state
                                          .cartDistanceKm(selectedAddress);
                                      final serverDeliveryFee =
                                          summary != null &&
                                              summary.containsKey('deliveryFee')
                                          ? (summary['deliveryFee'] as num?)
                                                ?.toDouble()
                                          : null;
                                      final calculatedDeliveryFee =
                                          serverDeliveryFee ??
                                          localDistanceFee ??
                                          (summary?['calculatedDeliveryFee']
                                                  as num?)
                                              ?.toDouble() ??
                                          (summary?['deliveryFee'] as num?)
                                              ?.toDouble() ??
                                          state.calculatedDeliveryFee;
                                      final gstAmount =
                                          (summary?['gstAmount'] as num?)
                                              ?.toDouble() ??
                                          state.gstAmount;
                                      final freeDeliveryUnlocked =
                                          (summary?['isFreeDelivery']
                                                  as bool?) ==
                                              true ||
                                          state.isFreeDelivery ||
                                          calculatedDeliveryFee <= 0 ||
                                          (state.freeDeliveryEnabled &&
                                              (state.freeDeliveryThreshold <=
                                                      0 ||
                                                  subtotal >=
                                                      state
                                                          .freeDeliveryThreshold));

                                      final effectiveDeliveryFee =
                                          freeDeliveryUnlocked
                                          ? 0.0
                                          : calculatedDeliveryFee;
                                      final total =
                                          subtotal +
                                          effectiveDeliveryFee +
                                          gstAmount;
                                      return _SummaryCard(
                                        items: state.cart,
                                        subtotal: subtotal,
                                        deliveryFee: effectiveDeliveryFee,
                                        gstAmount: gstAmount,
                                        total: total,
                                        distanceKm: deliveryDistance,
                                        chargePerKm:
                                            serverRatePerKm != null &&
                                                serverRatePerKm > 0
                                            ? serverRatePerKm
                                            : state.deliveryBaseCharge,
                                        deliveryBreakdown:
                                            effectiveDeliveryBreakdown,
                                        freeDeliveryUnlocked:
                                            freeDeliveryUnlocked,
                                        loading:
                                            snapshot.connectionState ==
                                                ConnectionState.waiting &&
                                            summary == null,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),

                            if (hasMultiVendorCart) ...[
                              const SizedBox(height: 20),
                              _Entrance(
                                index: 3,
                                child: _MultiVendorCard(labels: vendorLabels),
                              ),
                            ],

                            const SizedBox(height: 26),

                            // ── Payment methods ───────────────────────────
                            _Entrance(
                              index: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionLabel(
                                    icon: Icons.credit_card_rounded,
                                    text: 'Payment method',
                                  ),
                                  const SizedBox(height: 16),
                                  _Press3DButton(
                                    label: 'Place Cash On Delivery Order',
                                    icon: Icons.money_rounded,
                                    colors: const [
                                      Color(0xFFFF8A4C),
                                      Color(0xFFE8401A),
                                    ],
                                    edge: _kOrangeDeep,
                                    loading: _processingCod,
                                    loadingLabel: 'Placing order...',
                                    enabled: canOrder,
                                    onTap: () =>
                                        _placeCodOrder(state, selectedAddress!),
                                  ),
                                  const SizedBox(height: 14),
                                  _Press3DButton(
                                    label: 'Pay Online',
                                    icon: Icons.lock_rounded,
                                    colors: const [
                                      Color(0xFF8D86FF),
                                      Color(0xFF5851DB),
                                    ],
                                    edge: _kVioletDeep,
                                    loadingLabel: 'Opening payment...',
                                    enabled: canOrder,
                                    onTap: () =>
                                        _goToCashfree(state, selectedAddress!),
                                  ),
                                  const SizedBox(height: 18),
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
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  3D helpers
// ═════════════════════════════════════════════════════════════════════════════

/// Soft glowing orbs + gradient behind the whole page.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFF1E9), Color(0xFFF6F6FA), Color(0xFFF1F0FF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                right: -60,
                child: _Orb(size: 220, color: _kOrange.withValues(alpha: 0.22)),
              ),
              Positioned(
                top: 320,
                left: -90,
                child: _Orb(size: 240, color: _kViolet.withValues(alpha: 0.14)),
              ),
              Positioned(
                bottom: -80,
                right: -40,
                child: _Orb(size: 230, color: _kOrange.withValues(alpha: 0.14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// A glossy 3D sphere.
class _Sphere extends StatelessWidget {
  const _Sphere({required this.size, required this.colors});
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.45, -0.5),
          radius: 0.95,
          colors: colors,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.45),
            blurRadius: size * 0.45,
            offset: Offset(0, size * 0.22),
          ),
        ],
      ),
    );
  }
}

/// Staggered entrance: slides up while tilting forward in 3D.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 520 + index * 110),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, v, child) {
        return Opacity(
          opacity: v.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(0, (1 - v) * 30),
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX((1 - v) * 0.28),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Chunky 3D push-button: coloured edge underneath, face sinks when pressed.
class _Press3DButton extends StatefulWidget {
  const _Press3DButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.edge,
    required this.enabled,
    required this.onTap,
    required this.loadingLabel,
    this.loading = false,
  });

  final String label;
  final String loadingLabel;
  final IconData icon;
  final List<Color> colors;
  final Color edge;
  final bool enabled;
  final bool loading;
  final Future<void> Function() onTap;

  @override
  State<_Press3DButton> createState() => _Press3DButtonState();
}

class _Press3DButtonState extends State<_Press3DButton> {
  bool _down = false;
  bool _busy = false;

  Future<void> _handle() async {
    setState(() => _busy = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const face = 62.0;
    const depth = 8.0;
    final showLoading = widget.loading || _busy;
    final active = widget.enabled && !showLoading;
    final fg = active || showLoading ? Colors.white : Colors.grey.shade500;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: active ? (_) => setState(() => _down = true) : null,
      onTapUp: active
          ? (_) {
              setState(() => _down = false);
              HapticFeedback.lightImpact();
              _handle();
            }
          : null,
      onTapCancel: () => setState(() => _down = false),
      child: SizedBox(
        height: face + depth,
        width: double.infinity,
        child: Stack(
          children: [
            // Bottom edge (the "thickness" of the button)
            Positioned(
              left: 0,
              right: 0,
              top: depth,
              height: face,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.enabled ? widget.edge : const Color(0xFFBDBDBD),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: widget.enabled
                      ? [
                          BoxShadow(
                            color: widget.colors.last.withValues(
                              alpha: _down ? 0.18 : 0.42,
                            ),
                            blurRadius: _down ? 8 : 20,
                            offset: Offset(0, _down ? 4 : 12),
                          ),
                        ]
                      : const [],
                ),
              ),
            ),
            // Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 90),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _down ? depth - 1 : 0,
              height: face,
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: widget.enabled
                      ? LinearGradient(
                          colors: widget.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: widget.enabled ? null : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: Stack(
                  children: [
                    // glossy highlight
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: face / 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(
                                alpha: widget.enabled ? 0.3 : 0.5,
                              ),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: showLoading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.loadingLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(widget.icon, size: 19, color: fg),
                                const SizedBox(width: 9),
                                Text(
                                  widget.label,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: fg,
                                    shadows: active
                                        ? [
                                            Shadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              offset: const Offset(0, 1.5),
                                              blurRadius: 3,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTapDown: (_) => setState(() => _down = true),
            onTapUp: (_) {
              setState(() => _down = false);
              widget.onBack();
            },
            onTapCancel: () => setState(() => _down = false),
            child: SizedBox(
              width: 44,
              height: 50,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 6,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9E2),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 80),
                    left: 0,
                    right: 0,
                    top: _down ? 5 : 0,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Color(0xFFF3F3F8)],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: _kTextDark,
                      ),
                    ),
                  ),
                ],
              ),
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
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _kBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: _kGreen),
                SizedBox(width: 5),
                Text(
                  'Secure',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
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

// ─── Hero header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.0008)
        ..rotateX(0.04),
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF8A4C), Color(0xFFE8541A), Color(0xFFB83A0B)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: _kOrange.withValues(alpha: 0.45),
              blurRadius: 34,
              offset: const Offset(0, 20),
            ),
            BoxShadow(
              color: _kOrangeDeep.withValues(alpha: 0.35),
              blurRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            const Positioned(
              right: -6,
              top: -4,
              child: _Sphere(
                size: 92,
                colors: [
                  Color(0xFFFFE0D0),
                  Color(0xFFFFA27A),
                  Color(0xFFE8541A),
                ],
              ),
            ),
            const Positioned(
              right: 70,
              bottom: -10,
              child: _Sphere(
                size: 44,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFC9AE),
                  Color(0xFFFF8A4C),
                ],
              ),
            ),
            const Positioned(
              right: 26,
              bottom: 22,
              child: _Sphere(
                size: 22,
                colors: [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFD6C2),
                  Color(0xFFFFA27A),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Almost there',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Confirm delivery\nand payment',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Color(0x40000000),
                        offset: Offset(0, 3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Choose a delivery address and your preferred payment method.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF8A4C), Color(0xFFE8401A)],
            ),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              const BoxShadow(color: _kOrangeDeep, offset: Offset(0, 3)),
            ],
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: _kTextDark,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ─── Location tip ─────────────────────────────────────────────────────────────

class _LocationTipCard extends StatelessWidget {
  const _LocationTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9F2), Color(0xFFFFEEDC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEA580C).withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFEDD5), Color(0xFFFED7AA)],
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(color: Color(0xFFFDBA74), offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: Color(0xFFEA580C),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set your current location',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Use your current location or place the pin accurately to calculate the correct delivery charge.',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

class _GlassOutlineButton extends StatefulWidget {
  const _GlassOutlineButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_GlassOutlineButton> createState() => _GlassOutlineButtonState();
}

class _GlassOutlineButtonState extends State<_GlassOutlineButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _kOrange, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _kOrange.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
              BoxShadow(
                color: _kOrange.withValues(alpha: 0.25),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: _kOrange, size: 20),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  color: _kOrange,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Address Card (3D tilt when selected) ────────────────────────────────────

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
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: selected ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutBack,
        builder: (context, v, _) {
          return Transform.translate(
            offset: Offset(0, -10 * v),
            child: Transform.scale(
              scale: 1 + 0.035 * v,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0013)
                  ..rotateY(-0.13 * v)
                  ..rotateX(0.05 * v),
                child: _buildCard(v),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(double v) {
    final t = v.clamp(0.0, 1.0).toDouble();
    return Container(
      width: 235,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? const [Color(0xFFFFFFFF), Color(0xFFFFEDE4)]
              : const [Color(0xFFFFFFFF), Color(0xFFF7F7FA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Color.lerp(_kBorder, _kOrange, t)!,
          width: 1 + t,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(
              Colors.black.withValues(alpha: 0.06),
              _kOrange.withValues(alpha: 0.32),
              t,
            )!,
            blurRadius: 14 + 16 * t,
            offset: Offset(-6 * t, 10 + 8 * t),
          ),
          BoxShadow(
            color: Color.lerp(
              const Color(0xFFE9E9EF),
              const Color(0xFFFFC7AE),
              t,
            )!,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF8A4C), Color(0xFFE8401A)],
                        )
                      : null,
                  color: selected ? null : _kOrangeLight,
                  shape: BoxShape.circle,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _kOrange.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : const [],
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: selected ? Colors.white : _kOrange,
                ),
              ),
              const Spacer(),
              AnimatedScale(
                scale: selected ? 1 : 0.4,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: _kOrange,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: _kTextDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            data.line1,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
              height: 1.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? _kOrange.withValues(alpha: 0.1)
                  : const Color(0xFFF0F0F4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              data.shortAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _kOrangeDeep : _kTextMid,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────

String _storeNameForVendor(List<CartLine> cart, String vendorId) {
  for (final line in cart) {
    final lineVendorId = line.product.vendorId.trim().isEmpty
        ? 'main'
        : line.product.vendorId.trim();
    if (lineVendorId == vendorId &&
        line.product.supplierName.trim().isNotEmpty) {
      return line.product.supplierName.trim();
    }
  }
  return vendorId == 'main' ? 'Main Store' : vendorId;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.gstAmount,
    required this.total,
    this.distanceKm,
    this.chargePerKm,
    this.deliveryBreakdown = const [],
    this.freeDeliveryUnlocked,
    this.loading = false,
  });

  final List<CartLine> items;
  final double subtotal;
  final double deliveryFee;
  final double gstAmount;
  final double total;
  final double? distanceKm;
  final double? chargePerKm;
  final List<DeliveryChargeBreakdown> deliveryBreakdown;
  final bool? freeDeliveryUnlocked;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final isFree =
        freeDeliveryUnlocked ??
        (deliveryFee <= 0 ||
            appState.isFreeDelivery ||
            (appState.freeDeliveryEnabled &&
                (appState.freeDeliveryThreshold <= 0 ||
                    subtotal >= appState.freeDeliveryThreshold)));
    final effectiveDeliveryFee = isFree ? 0.0 : deliveryFee;
    final effectiveTotal = subtotal + effectiveDeliveryFee + gstAmount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // stacked "paper" layers behind the card for depth
          Positioned(
            left: 26,
            right: 26,
            top: 24,
            bottom: -14,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEDEDF3),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          Positioned(
            left: 13,
            right: 13,
            top: 12,
            bottom: -7,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7FB),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFE6E6EE)),
              ),
            ),
          ),
          Transform(
            alignment: Alignment.topCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0006)
              ..rotateX(0.012),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFFFFAF7)],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.08),
                    blurRadius: 40,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (loading) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        minHeight: 3,
                        color: _kOrange,
                        backgroundColor: _kOrangeLight,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF8A4C), Color(0xFFE8401A)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                            const BoxShadow(
                              color: _kOrangeDeep,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order summary',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _kTextDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Review your charges before payment',
                              style: TextStyle(fontSize: 12, color: _kTextMid),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'ITEMS IN YOUR CART',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: _kTextMid,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Text(
                      'No items in cart',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    ...items.map(
                      (line) => Container(
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _kBorder),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            const BoxShadow(
                              color: Color(0xFFF0F0F4),
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _kOrangeLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'x${line.quantity}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: _kOrange,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                line.product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _kTextDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Rs ${line.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _kTextDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  const Text(
                    'CHARGES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: _kTextMid,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SummaryRow(
                    label: 'Subtotal',
                    value: subtotal,
                    bold: true,
                    valueColor: _kOrange,
                  ),
                  const SizedBox(height: 10),
                  if (deliveryBreakdown.isNotEmpty) ...[
                    const Text(
                      'Delivery fee by store',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...deliveryBreakdown.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: _StoreDeliveryFeeRow(
                          storeName: entry.storeName,
                          distanceKm: entry.distanceKm,
                          chargePerKm: chargePerKm,
                          value: isFree ? 0 : entry.fee,
                          valueText: isFree ? 'Rs 0.00' : null,
                          valueColor: isFree ? _kGreen : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: _SummaryRow(
                        label: 'Total delivery fee',
                        value: effectiveDeliveryFee,
                        valueText: isFree ? 'Rs 0.00' : null,
                        valueColor: isFree ? _kGreen : null,
                        bold: true,
                      ),
                    ),
                  ] else
                    _SummaryRow(
                      label: 'Delivery fee',
                      value: effectiveDeliveryFee,
                      valueText: effectiveDeliveryFee <= 0 ? 'Rs 0.00' : null,
                      valueColor: effectiveDeliveryFee <= 0 ? _kGreen : null,
                    ),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'GST', value: gstAmount),
                  if (appState.freeDeliveryEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isFree
                              ? const Color(0xFFF0FDF4)
                              : const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFree
                                ? const Color(0xFFBBF7D0)
                                : const Color(0xFFFED7AA),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isFree
                                  ? Icons.check_circle_rounded
                                  : Icons.local_shipping_outlined,
                              size: 16,
                              color: isFree ? _kGreen : const Color(0xFFEA580C),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                isFree
                                    ? 'FREE delivery applied!'
                                    : ((appState.freeDeliveryThreshold -
                                                  subtotal) >
                                              0
                                          ? 'Add Rs ${(appState.freeDeliveryThreshold - subtotal).toStringAsFixed(0)} more to get FREE delivery'
                                          : 'FREE delivery applied!'),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: isFree
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF9A3412),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 14),
                  // Final total — dark raised slab
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kInk2, _kInk],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kInk.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 12),
                        ),
                        const BoxShadow(
                          color: Color(0xFF0A0A10),
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          color: Color(0xFFFFB38F),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'FINAL TOTAL',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        Text(
                          'Rs ${effectiveTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFB38F),
                            shadows: [
                              Shadow(
                                color: _kOrange.withValues(alpha: 0.7),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    this.valueText,
    this.valueColor,
  });

  final String label;
  final double value;
  final bool bold;
  final String? valueText;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final displayText = valueText ?? 'Rs ${value.toStringAsFixed(2)}';
    final textColor = valueColor ?? (bold ? _kOrange : _kTextDark);
    final labelStyle = TextStyle(
      fontSize: bold ? 17 : 15,
      height: 1.25,
      color: bold ? _kTextDark : const Color(0xFF666666),
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
    );
    final valueStyle = TextStyle(
      fontSize: bold ? 20 : 15,
      height: 1.2,
      color: textColor,
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 280;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: labelStyle),
                    const SizedBox(height: 3),
                    Text(displayText, style: valueStyle),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        softWrap: true,
                        style: labelStyle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(displayText, style: valueStyle),
                  ],
                ),
        );
      },
    );
  }
}

class _StoreDeliveryFeeRow extends StatelessWidget {
  const _StoreDeliveryFeeRow({
    required this.storeName,
    required this.distanceKm,
    required this.chargePerKm,
    required this.value,
    this.valueText,
    this.valueColor,
  });

  final String storeName;
  final double distanceKm;
  final double? chargePerKm;
  final double value;
  final String? valueText;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    // Very small distances can round to 0.00 km while the backend still
    // applies the configured minimum/base delivery fee.
    final explanation = distanceKm < 0.005
        ? 'Minimum delivery fee'
        : '${distanceKm.toStringAsFixed(2)} km × ₹${chargePerKm?.toStringAsFixed(2) ?? '0.00'}/km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.storefront_rounded, size: 15, color: _kOrange),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  maxLines: 2,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  explanation,
                  maxLines: 2,
                  softWrap: true,
                  style: const TextStyle(fontSize: 10, color: _kTextMid),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            valueText ?? 'Rs ${value.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: valueColor ?? _kTextDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Multi-vendor card ────────────────────────────────────────────────────────

class _MultiVendorCard extends StatelessWidget {
  const _MultiVendorCard({required this.labels});
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          const BoxShadow(color: Color(0xFFEFEFF4), offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0xFFFFD2C1), offset: Offset(0, 3)),
                  ],
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: _kOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Stores in your cart',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This cart will be split into separate orders by store.',
            style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: labels
                .map(
                  (label) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _kOrangeLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _kOrange.withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _kOrange.withValues(alpha: 0.12),
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _kOrange,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4EE), Color(0xFFFFE6DB)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kOrange.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.16),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_shipping_rounded, size: 18, color: _kOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Delivering to: $address',
              style: const TextStyle(
                fontSize: 12.5,
                color: _kOrangeDeep,
                fontWeight: FontWeight.w700,
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
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(color: Color(0xFFEFEFF4), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kOrangeLight,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0xFFFFD2C1), offset: Offset(0, 3)),
              ],
            ),
            child: Icon(icon, color: _kOrange, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: _kOrange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
