import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/app_button.dart';
import '../app_page.dart';
import 'order_success_screen.dart';

class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  static const routeName = '/checkout';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Checkout',
      children: [
        const _AddressField(),
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
            label: 'Pay with Razorpay',
            icon: Icons.currency_rupee,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await state.checkout(address: _AddressField.address);
              if (state.error != null) {
                messenger.showSnackBar(SnackBar(content: Text(state.error!)));
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
