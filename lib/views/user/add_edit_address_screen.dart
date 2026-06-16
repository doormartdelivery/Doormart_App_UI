import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/app_state.dart';

class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key, this.address});

  static const routeName = '/address/edit';
  final AddressModel? address;

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    if (address != null) {
      _label.text = address.label;
      _line1.text = address.line1;
      _city.text = address.city;
      _pincode.text = address.pincode;
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _city.dispose();
    _pincode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.address != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Address' : 'Add Address')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _label,
                  decoration: const InputDecoration(labelText: 'Label', hintText: 'Home, Work, etc.'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter a label' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _line1,
                  decoration: const InputDecoration(labelText: 'Address line'),
                  maxLines: 3,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter address line' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _city,
                  decoration: const InputDecoration(labelText: 'City'),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter city' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pincode,
                  decoration: const InputDecoration(labelText: 'Pincode'),
                  keyboardType: TextInputType.number,
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Enter pincode' : null,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(editing ? 'Update Address' : 'Save Address'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final state = context.read<AppState>();
    try {
      if (widget.address == null) {
        await state.createAddress(
          label: _label.text.trim(),
          line1: _line1.text.trim(),
          city: _city.text.trim(),
          pincode: _pincode.text.trim(),
        );
      } else {
        await state.updateAddress(
          addressId: widget.address!.id,
          label: _label.text.trim(),
          line1: _line1.text.trim(),
          city: _city.text.trim(),
          pincode: _pincode.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
