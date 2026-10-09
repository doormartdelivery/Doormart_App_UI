import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../admin/admin_logout_confirm.dart';
import '../admin/admin_sidebar_drawer.dart';

const Color _kBg = Color(0xFFF6F6F6);
const Color _kCard = Colors.white;
const Color _kOrange = Color(0xFFE8541A);
const Color _kOrangeLight = Color(0xFFFFF0EB);
const Color _kTextDark = Color(0xFF1E293B);
const Color _kTextMuted = Color(0xFF64748B);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kSuccess = Color(0xFF16A34A);

class DeliveryChargesScreen extends StatefulWidget {
  const DeliveryChargesScreen({super.key});

  static const routeName = '/super-admin/delivery-charges';

  @override
  State<DeliveryChargesScreen> createState() => _DeliveryChargesScreenState();
}

class _DeliveryChargesScreenState extends State<DeliveryChargesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Distance & Basic Pricing
  late final TextEditingController _fallbackFeeController;
  late final TextEditingController _baseDistanceController;
  late final TextEditingController _baseChargeController;
  late final TextEditingController _perKmController;
  late final TextEditingController _gstController;
  bool _distanceBasedDelivery = false;

  // Free Delivery
  bool _freeDeliveryEnabled = true;
  late final TextEditingController _freeDeliveryThresholdController;

  // Shift Pricing
  bool _shiftChargesEnabled = false;
  late final TextEditingController _dayChargeController;
  late final TextEditingController _nightChargeController;
  late final TextEditingController _dayShiftStartController;
  late final TextEditingController _dayShiftEndController;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _fallbackFeeController = TextEditingController();
    _baseDistanceController = TextEditingController();
    _baseChargeController = TextEditingController();
    _perKmController = TextEditingController();
    _gstController = TextEditingController();

    _freeDeliveryThresholdController = TextEditingController();

    _dayChargeController = TextEditingController();
    _nightChargeController = TextEditingController();
    _dayShiftStartController = TextEditingController();
    _dayShiftEndController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _fallbackFeeController.dispose();
    _baseDistanceController.dispose();
    _baseChargeController.dispose();
    _perKmController.dispose();
    _gstController.dispose();
    _freeDeliveryThresholdController.dispose();
    _dayChargeController.dispose();
    _nightChargeController.dispose();
    _dayShiftStartController.dispose();
    _dayShiftEndController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final state = context.read<AppState>();
    await state.loadCheckoutSettings();
    if (!mounted) return;

    _populateFromState(state);
    setState(() {
      _isLoading = false;
      _initialized = true;
    });
  }

  void _populateFromState(AppState state) {
    _fallbackFeeController.text = state.deliveryChargeAmount.toStringAsFixed(0);
    _distanceBasedDelivery = state.distanceBasedDelivery;
    _baseDistanceController.text =
        state.deliveryBaseDistanceKm.toStringAsFixed(0);
    _baseChargeController.text = state.deliveryBaseCharge.toStringAsFixed(0);
    _perKmController.text = state.deliveryPerKmCharge.toStringAsFixed(0);
    _gstController.text = state.gstPercent.toStringAsFixed(0);

    _freeDeliveryEnabled = state.freeDeliveryEnabled;
    _freeDeliveryThresholdController.text =
        state.freeDeliveryThreshold.toStringAsFixed(0);

    _shiftChargesEnabled = state.shiftChargesEnabled;
    _dayChargeController.text = state.dayDeliveryCharge.toStringAsFixed(0);
    _nightChargeController.text = state.nightDeliveryCharge.toStringAsFixed(0);
    _dayShiftStartController.text = state.dayShiftStart;
    _dayShiftEndController.text = state.dayShiftEnd;
  }

  double _cleanDouble(String text, {double fallback = 0.0}) {
    final clean = text.replaceAll(RegExp(r'[^0-9.]'), '').trim();
    if (clean.isEmpty) return fallback;
    return double.tryParse(clean) ?? fallback;
  }

  Future<void> _save() async {
    final fallbackFee = _cleanDouble(_fallbackFeeController.text, fallback: -1);
    final baseDist = _cleanDouble(_baseDistanceController.text, fallback: -1);
    final baseCharge = _cleanDouble(_baseChargeController.text, fallback: -1);
    final perKm = _cleanDouble(_perKmController.text, fallback: -1);
    final gst = _cleanDouble(_gstController.text, fallback: -1);
    final freeThreshold = _cleanDouble(_freeDeliveryThresholdController.text, fallback: 0);
    final dayCharge = _cleanDouble(_dayChargeController.text, fallback: -1);
    final nightCharge = _cleanDouble(_nightChargeController.text, fallback: -1);
    final dayStart = _dayShiftStartController.text.trim();
    final dayEnd = _dayShiftEndController.text.trim();

    final timeRegex = RegExp(r'^([01]?\d|2[0-3]):([0-5]\d)$');

    if (fallbackFee < 0) {
      _showToast('Enter a valid non-negative fixed fallback fee');
      return;
    }
    if (baseDist < 0) {
      _showToast('Enter a valid non-negative base distance');
      return;
    }
    if (baseCharge < 0) {
      _showToast('Enter a valid non-negative base charge');
      return;
    }
    if (perKm < 0) {
      _showToast('Enter a valid non-negative per-km charge');
      return;
    }
    if (gst < 0 || gst > 100) {
      _showToast('Enter a valid GST percentage (0 - 100)');
      return;
    }
    if (freeThreshold < 0) {
      _showToast('Enter a valid non-negative free delivery threshold');
      return;
    }
    if (dayCharge < 0) {
      _showToast('Enter a valid non-negative day shift charge');
      return;
    }
    if (nightCharge < 0) {
      _showToast('Enter a valid non-negative night shift charge');
      return;
    }
    if (!timeRegex.hasMatch(dayStart)) {
      _showToast('Day shift start time must be in HH:mm format (e.g. 06:00)');
      return;
    }
    if (!timeRegex.hasMatch(dayEnd)) {
      _showToast('Day shift end time must be in HH:mm format (e.g. 22:00)');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final state = context.read<AppState>();
      await state.saveCheckoutSettings(
        deliveryChargeAmount: fallbackFee,
        gstPercent: gst,
        distanceBasedDelivery: _distanceBasedDelivery,
        deliveryBaseDistanceKm: baseDist,
        deliveryBaseCharge: baseCharge,
        deliveryPerKmCharge: perKm,
        freeDeliveryEnabled: _freeDeliveryEnabled,
        freeDeliveryThreshold: freeThreshold,
        shiftChargesEnabled: _shiftChargesEnabled,
        dayDeliveryCharge: dayCharge,
        nightDeliveryCharge: nightCharge,
        dayShiftStart: dayStart,
        dayShiftEnd: dayEnd,
      );
      if (!mounted) return;
      _populateFromState(state);
      _showToast('Delivery charges saved successfully', isError: false);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showToast(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : _kSuccess,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    final isSuperAdmin = user?.role == UserRoles.superAdmin;

    if (!isSuperAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Text(
            'Only Super Admin is authorized to access Delivery Charges Management.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: AdminSidebarDrawer(
        currentRoute: DeliveryChargesScreen.routeName,
        onLogout: () async {
          if (!await confirmAdminLogout(context)) return;
          if (!context.mounted) return;
          Navigator.pop(context);
          final logoutRoute = context.read<AppState>().logoutRouteName;
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            logoutRoute,
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: _isLoading && !_initialized
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    _buildModeCard(),
                    const SizedBox(height: 16),
                    _buildDistancePricingCard(),
                    const SizedBox(height: 16),
                    _buildFreeDeliveryCard(),
                    const SizedBox(height: 16),
                    _buildShiftChargesCard(),
                    const SizedBox(height: 16),
                    _buildCurrentConfigCard(),
                    const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu, color: _kOrange, size: 26),
            tooltip: 'Menu',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Charges Management',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Super Admin Delivery Pricing Control Center',
                  style: TextStyle(
                    fontSize: 13,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh, color: _kOrange),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return _SectionCard(
      title: '1. Delivery Fee Mode',
      subtitle:
          'Choose between distance-based calculation or standard fixed delivery fee. All customer checkouts use this rule automatically.',
      icon: Icons.alt_route_rounded,
      child: SwitchListTile.adaptive(
        value: _distanceBasedDelivery,
        onChanged: (val) => setState(() => _distanceBasedDelivery = val),
        contentPadding: EdgeInsets.zero,
        activeThumbColor: _kOrange,
        title: const Text(
          'Calculate delivery fee by distance',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Text(
          _distanceBasedDelivery
              ? 'Active: Distance-based calculation from store pickup to customer.'
              : 'Active: Fixed fee mode using the fallback fee amount.',
          style: TextStyle(color: _kTextMuted, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildDistancePricingCard() {
    return _SectionCard(
      title: '2. Distance-based Charges',
      subtitle:
          'Configure base rates, per-kilometer pricing, delivery radius, and GST percentage.',
      icon: Icons.social_distance_rounded,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth > 720
              ? (constraints.maxWidth - 36) / 3
              : constraints.maxWidth > 460
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          Widget field(
            TextEditingController controller,
            String label, {
            String? prefix,
            String? suffix,
          }) {
            return SizedBox(
              width: itemWidth,
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  labelText: label,
                  prefixText: prefix,
                  suffixText: suffix,
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kOrange, width: 2),
                  ),
                ),
              ),
            );
          }

          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              field(
                _fallbackFeeController,
                'Fixed fallback fee',
                prefix: 'Rs ',
              ),
              field(_baseDistanceController, 'Base distance', suffix: 'km'),
              field(_baseChargeController, 'Base charge', prefix: 'Rs '),
              field(_perKmController, 'Extra per km', prefix: 'Rs '),
              field(_gstController, 'GST', suffix: '%'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFreeDeliveryCard() {
    return _SectionCard(
      title: '3. Free Delivery',
      subtitle:
          'Set a dynamic minimum order threshold. Eligible orders equal to or above this amount automatically receive FREE delivery (₹0 fee).',
      icon: Icons.local_offer_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: _freeDeliveryEnabled,
            onChanged: (val) => setState(() => _freeDeliveryEnabled = val),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _kSuccess,
            title: const Text(
              'Enable Free Delivery',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: Text(
              _freeDeliveryEnabled
                  ? 'Active: Free delivery will be applied to qualifying orders.'
                  : 'Disabled: All orders pay configured delivery fee.',
              style: TextStyle(color: _kTextMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _freeDeliveryThresholdController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (val) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Free Delivery Threshold',
                prefixText: 'Rs ',
                helperText: 'Orders above or equal to this qualify for free delivery',
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _kSuccess, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _kOrangeLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: _kOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _freeDeliveryEnabled
                        ? () {
                            final raw = _freeDeliveryThresholdController.text
                                .replaceAll(RegExp(r'[^0-9.]'), '')
                                .trim();
                            if (raw.isEmpty) {
                              return 'Customer rule: Please enter a threshold amount (e.g. Rs 199, Rs 299) or enter 0 for all orders.';
                            }
                            final val = double.tryParse(raw);
                            if (val == null || val <= 0) {
                              return 'Customer rule: Free delivery active for all orders (₹0 threshold).';
                            }
                            return 'Customer rule: If cart subtotal >= Rs ${val.toStringAsFixed(0)}, Delivery = FREE.';
                          }()
                        : 'Free delivery is currently disabled. Standard calculation applies.',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftChargesCard() {
    return _SectionCard(
      title: '4. Shift-based Delivery Charges',
      subtitle:
          'Optionally apply different delivery fees depending on delivery time window (Day Shift vs. Night Shift).',
      icon: Icons.access_time_filled_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: _shiftChargesEnabled,
            onChanged: (val) => setState(() => _shiftChargesEnabled = val),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: _kOrange,
            title: const Text(
              'Enable Shift-based Delivery Charges',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            subtitle: Text(
              _shiftChargesEnabled
                  ? 'Active: Fees dynamically switch between Day & Night shift.'
                  : 'Disabled: Standard fixed or distance rates apply all day.',
              style: TextStyle(color: _kTextMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth > 600
                  ? (constraints.maxWidth - 24) / 2
                  : constraints.maxWidth;

              Widget field(
                TextEditingController controller,
                String label, {
                String? prefix,
                String? helper,
                TextInputType? keyboardType,
              }) {
                return SizedBox(
                  width: itemWidth,
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: label,
                      prefixText: prefix,
                      helperText: helper,
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kOrange, width: 2),
                      ),
                    ),
                  ),
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  field(
                    _dayChargeController,
                    'Day Shift Charge',
                    prefix: 'Rs ',
                    helper: 'Applied during day shift window',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  field(
                    _nightChargeController,
                    'Night Shift Charge',
                    prefix: 'Rs ',
                    helper: 'Applied during night shift window',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  field(
                    _dayShiftStartController,
                    'Day Shift Start (24h)',
                    helper: 'e.g. 06:00 (6:00 AM)',
                  ),
                  field(
                    _dayShiftEndController,
                    'Day Shift End (24h)',
                    helper: 'e.g. 22:00 (10:00 PM)',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Shift Window Rule: Day Shift runs from ${_dayShiftStartController.text.trim()} to ${_dayShiftEndController.text.trim()}. Outside this window, Night Shift applies automatically.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _kTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentConfigCard() {
    final state = context.watch<AppState>();
    final liveFallback = _cleanDouble(_fallbackFeeController.text, fallback: state.deliveryChargeAmount);
    final liveThreshold = _cleanDouble(_freeDeliveryThresholdController.text, fallback: state.freeDeliveryThreshold);
    final liveDay = _cleanDouble(_dayChargeController.text, fallback: state.dayDeliveryCharge);
    final liveNight = _cleanDouble(_nightChargeController.text, fallback: state.nightDeliveryCharge);
    final liveBaseDist = _cleanDouble(_baseDistanceController.text, fallback: state.deliveryBaseDistanceKm);
    final liveBaseCharge = _cleanDouble(_baseChargeController.text, fallback: state.deliveryBaseCharge);
    final livePerKm = _cleanDouble(_perKmController.text, fallback: state.deliveryPerKmCharge);
    final liveGst = _cleanDouble(_gstController.text, fallback: state.gstPercent);
    final liveStart = _dayShiftStartController.text.trim().isEmpty ? state.dayShiftStart : _dayShiftStartController.text.trim();
    final liveEnd = _dayShiftEndController.text.trim().isEmpty ? state.dayShiftEnd : _dayShiftEndController.text.trim();

    return _SectionCard(
      title: '5. Current Configuration (Live Values)',
      subtitle:
          'Live values actively configured on this screen. Saved directly to backend upon saving.',
      icon: Icons.check_circle_outline_rounded,
      child: Column(
        children: [
          _ConfigRow(
            label: 'Mode',
            value: _distanceBasedDelivery ? 'Distance Based' : 'Fixed Fee',
          ),
          _ConfigRow(
            label: 'Fixed Fallback Fee',
            value: 'Rs ${liveFallback.toStringAsFixed(0)}',
          ),
          _ConfigRow(
            label: 'Free Delivery',
            value: _freeDeliveryEnabled
                ? 'Enabled (Threshold: Rs ${liveThreshold.toStringAsFixed(0)})'
                : 'Disabled',
            valueColor: _freeDeliveryEnabled ? _kSuccess : null,
          ),
          _ConfigRow(
            label: 'Shift Pricing',
            value: _shiftChargesEnabled
                ? 'Enabled (Day: Rs ${liveDay.toStringAsFixed(0)}, Night: Rs ${liveNight.toStringAsFixed(0)})'
                : 'Disabled',
          ),
          if (_shiftChargesEnabled)
            _ConfigRow(
              label: 'Day Shift Window',
              value: '$liveStart - $liveEnd',
            ),
          _ConfigRow(
            label: 'Distance Base Range',
            value:
                '${liveBaseDist.toStringAsFixed(0)} km @ Rs ${liveBaseCharge.toStringAsFixed(0)}',
          ),
          _ConfigRow(
            label: 'Extra Per Km',
            value: 'Rs ${livePerKm.toStringAsFixed(0)} / km',
          ),
          _ConfigRow(
            label: 'Current GST',
            value: '${liveGst.toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _save,
        style: FilledButton.styleFrom(
          backgroundColor: _kOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
        ),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save_rounded, size: 22),
        label: Text(
          _isSaving ? 'Saving Charges...' : 'Save Delivery Charges',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
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
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _kOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: _kTextMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  const _ConfigRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _kTextMuted,
            ),
          ),
          Text(
            value,
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
