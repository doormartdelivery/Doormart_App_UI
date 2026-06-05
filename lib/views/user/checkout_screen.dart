import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/app_button.dart';
import '../../widgets/toast_widget.dart';
import '../app_page.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'razorpay';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Checkout',
      bottomNavIndex: 2,
      children: [
        const _AddressField(),
        const SizedBox(height: 12),
        _PaymentMethodCard(
          selectedMethod: _paymentMethod,
          onChanged: (value) => setState(() => _paymentMethod = value),
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, state, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(
                    'Items',
                    'Rs ${state.subtotal.toStringAsFixed(0)}',
                  ),
                  _SummaryRow(
                    'Delivery',
                    'Rs ${state.deliveryFee.toStringAsFixed(0)}',
                  ),
                  const Divider(),
                  _SummaryRow(
                    'Payable',
                    'Rs ${state.total.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
          ),
        ),
        Consumer<AppState>(
          builder: (context, state, _) => AppButton(
            label: _paymentMethod == 'cod'
                ? 'Place COD Order'
                : 'Pay with Razorpay',
            icon: _paymentMethod == 'cod'
                ? Icons.payments
                : Icons.currency_rupee,
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await state.checkout(
                  address: _AddressField.address,
                  paymentMethod: _paymentMethod,
                );
                if (!context.mounted) return;
                showToast(
                  context,
                  _paymentMethod == 'cod'
                      ? 'COD order placed'
                      : 'Payment successful',
                );
              } catch (error) {
                if (!context.mounted) return;
                showToast(context, error.toString());
                return;
              }
              navigator.pushReplacementNamed(OrderSuccessScreen.routeName);
            },
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.selectedMethod,
    required this.onChanged,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              title: 'Razorpay',
              subtitle: 'UPI, card, wallet, or net banking',
              icon: Icons.currency_rupee,
              value: 'razorpay',
              selectedMethod: selectedMethod,
              onChanged: onChanged,
            ),
            const SizedBox(height: 8),
            _PaymentOption(
              title: 'Cash on Delivery',
              subtitle: 'Pay by cash when your order arrives',
              icon: Icons.payments,
              value: 'cod',
              selectedMethod: selectedMethod,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedMethod,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final String selectedMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = selectedMethod == value;
    final color = selected ? const Color(0xFF0F766E) : const Color(0xFF64748B);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => onChanged(value),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF7EF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF12372A)
                            : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Radio<String>(
                value: value,
                groupValue: selectedMethod,
                onChanged: (method) {
                  if (method != null) onChanged(method);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressField extends StatelessWidget {
  const _AddressField();

  static String address = 'Anna Nagar, Chennai';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: address,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.home_work),
        labelText: 'Delivery address',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => address = value,
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
