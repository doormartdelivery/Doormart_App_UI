import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/app_state.dart';
import '../../features/operations/services/location_service.dart';

const _accent = Color(0xFFFF6A13);
const _bg = Color(0xFFF7F8FC);
const _card = Colors.white;
const _border = Color(0xFFE8EAF2);
const _textDark = Color(0xFF1B2330);
const _textMid = Color(0xFF667085);

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key, this.address});

  static const routeName = '/address/edit';
  final AddressModel? address;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Home');
  final _house = TextEditingController();
  final _apartment = TextEditingController();
  final _landmark = TextEditingController();
  bool _defaultAddress = false;
  bool _saving = false;
  bool _capturingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    if (address != null) {
      _label.text = address.label;
      _house.text = address.line1;
      _apartment.text = address.city;
      _landmark.text = address.pincode;
      _latitude = address.latitude;
      _longitude = address.longitude;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _house.dispose();
    _apartment.dispose();
    _landmark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final editing = widget.address != null;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 26,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      editing ? 'Edit Address' : 'Add New Address',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _textDark,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  const Text(
                    'ADDRESS LABEL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _textMid,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _LabelChip(label: 'Home', icon: Icons.home_rounded, selected: _label.text == 'Home', onTap: () => setState(() => _label.text = 'Home')),
                      const SizedBox(width: 10),
                      _LabelChip(label: 'Work', icon: Icons.work_outline_rounded, selected: _label.text == 'Work', onTap: () => setState(() => _label.text = 'Work')),
                      const SizedBox(width: 10),
                      _LabelChip(label: 'Other', icon: Icons.more_horiz_rounded, selected: _label.text == 'Other', onTap: () => setState(() => _label.text = 'Other')),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _Field(
                    label: 'HOUSE / FLAT / BLOCK NO.',
                    hint: 'e.g. Building 4A, Suite 201',
                    controller: _house,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'APARTMENT / ROAD / AREA',
                    hint: 'e.g. Innovation Drive, Tech District',
                    controller: _apartment,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 14),
                  _Field(
                    label: 'LANDMARK',
                    optional: true,
                    hint: 'e.g. Near Central Park Fountain',
                    controller: _landmark,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 14),
                  _LocationCard(
                    latitude: _latitude,
                    longitude: _longitude,
                    loading: _capturingLocation,
                    onUseCurrentLocation: _captureLocation,
                    onClear: _latitude != null || _longitude != null
                        ? () => setState(() {
                            _latitude = null;
                            _longitude = null;
                          })
                        : null,
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _defaultAddress,
                    onChanged: (value) => setState(() => _defaultAddress = value),
                    activeColor: _accent,
                    title: const Text(
                      'Set as default address',
                      style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    subtitle: const Text(
                      'Quickly select this for future orders',
                      style: TextStyle(color: _textMid, fontSize: 12),
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(editing ? 'Update Address' : 'Save Address'),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_house.text.trim().isEmpty) return;
    if (_apartment.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      final label = _label.text.trim().isEmpty ? 'Home' : _label.text.trim();
      final line1 = _house.text.trim();
      final city = _apartment.text.trim();
      final pincode = _landmark.text.trim().isEmpty ? 'N/A' : _landmark.text.trim();

      if (widget.address == null) {
        await state.createAddress(
          label: label,
          line1: line1,
          city: city,
          pincode: pincode,
          latitude: _latitude,
          longitude: _longitude,
        );
      } else {
        await state.updateAddress(
          addressId: widget.address!.id,
          label: label,
          line1: line1,
          city: city,
          pincode: pincode,
          latitude: _latitude,
          longitude: _longitude,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _capturingLocation = true);
    try {
      final location = await LocationService().currentLocation();
      if (!mounted) return;
      setState(() {
        _latitude = location.latitude;
        _longitude = location.longitude;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _capturingLocation = false);
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.hint,
    required this.controller,
    this.optional = false,
    this.maxLines = 1,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool optional;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: _textMid,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              const Text('(OPTIONAL)', style: TextStyle(fontSize: 10, color: _textMid)),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF9FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _accent, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.latitude,
    required this.longitude,
    required this.loading,
    required this.onUseCurrentLocation,
    required this.onClear,
  });

  final double? latitude;
  final double? longitude;
  final bool loading;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LOCATION PIN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: _textMid,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasLocation
                ? 'Saved pin: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
                : 'No pin saved yet. Use your current location for exact delivery navigation.',
            style: const TextStyle(fontSize: 12.5, color: _textDark, height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: loading ? null : onUseCurrentLocation,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Use current location'),
                ),
              ),
              if (onClear != null) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: onClear,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFFF1E8) : const Color(0xFFF9FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _accent : _border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? _accent : _textMid),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? _accent : _textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
