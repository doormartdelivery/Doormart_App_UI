import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/address_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/toast_widget.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedAddressId;
  bool _initialLoadDone = false;
  bool _processing = false;

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

  AddressModel? _selectedAddress(AppState state) {
    if (state.savedAddresses.isEmpty) return null;
    final selectedId = _selectedAddressId ?? state.selectedAddress?.id;
    return state.savedAddresses.firstWhere(
      (address) => address.id == selectedId,
      orElse: () => state.savedAddresses.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      body: SafeArea(
        child: Consumer<AppState>(
          builder: (context, state, _) {
            final addresses = state.savedAddresses;
            final selectedAddress = _selectedAddress(state);
            final addressText = selectedAddress?.fullAddress ?? '';

            return Column(
              children: [
                _TopBar(onBack: () => Navigator.pop(context)),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Confirm delivery\nand payment',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose the saved address from your account and place the order securely.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: Colors.black.withValues(alpha: 0.58),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle('Saved addresses'),
                        const SizedBox(height: 12),
                        if (addresses.isEmpty)
                          const _EmptyStateCard(
                            title: 'No saved addresses',
                            subtitle: 'Add an address from your profile to continue.',
                          )
                        else
                          SizedBox(
                            height: 168,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: addresses.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final addr = addresses[index];
                                return _AddressCard(
                                  data: addr,
                                  selected: _selectedAddressId == addr.id ||
                                      (_selectedAddressId == null &&
                                          state.selectedAddress?.id == addr.id),
                                  onTap: () => setState(() => _selectedAddressId = addr.id),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 24),
                        const _SectionTitle('Order summary'),
                        const SizedBox(height: 12),
                        _SummaryCard(
                          deliveryFee: state.deliveryFee,
                          subtotal: state.subtotal,
                          total: state.total,
                        ),
                        const SizedBox(height: 24),
                        _CheckoutButton(
                          processing: _processing,
                          label: 'Place COD Order',
                          onPressed: addresses.isEmpty || state.cart.isEmpty
                              ? null
                              : () async {
                                  if (selectedAddress == null) {
                                    showToast(context, 'Please select an address');
                                    return;
                                  }
                                  setState(() => _processing = true);
                                  try {
                                    await state.checkout(
                                      address: selectedAddress.fullAddress,
                                      paymentMethod: 'cod',
                                    );
                                    if (!context.mounted) return;
                                    showToast(context, 'COD order placed');
                                    if (!context.mounted) return;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      OrderSuccessScreen.routeName,
                                    );
                                  } catch (error) {
                                    if (!context.mounted) return;
                                    showToast(context, error.toString());
                                  } finally {
                                    if (mounted) setState(() => _processing = false);
                                  }
                                },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          addressText.isEmpty
                              ? 'Selected address will appear here after you choose one.'
                              : 'Delivering to: $addressText',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.black.withValues(alpha: 0.52),
                            height: 1.4,
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
    );
  }
}

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
              child: const Icon(Icons.chevron_left_rounded, size: 26, color: Color(0xFF1A1A1A)),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Checkout',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1A1A1A),
      ),
    );
  }
}

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
        duration: const Duration(milliseconds: 180),
        width: 210,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? const Color(0xFFE8541A) : const Color(0xFFE8E8E8),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFE8541A) : const Color(0xFFFFF0EB),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: selected ? Colors.white : const Color(0xFFE8541A),
                  ),
                ),
                const Spacer(),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFFE8541A), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              data.line1,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF666666),
                height: 1.4,
              ),
            ),
            const Spacer(),
            Text(
              data.shortAddress,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.deliveryFee,
    required this.subtotal,
    required this.total,
  });

  final double deliveryFee;
  final double subtotal;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          _SummaryRow(label: 'Delivery Charge', value: 'Rs ${deliveryFee.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Subtotal', value: 'Rs ${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Total', value: 'Rs ${total.toStringAsFixed(2)}', bold: true),
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
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: const Color(0xFF666666),
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 16 : 14,
            color: const Color(0xFF1A1A1A),
            fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  const _CheckoutButton({
    required this.onPressed,
    required this.label,
    required this.processing,
  });

  final VoidCallback? onPressed;
  final String label;
  final bool processing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE8541A),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8541A).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: processing ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: processing
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFFE8541A)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}
