import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});
  static const routeName = '/payment';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Payment',
    icon: Icons.payments,
    description: 'Razorpay UPI, cards, wallet, net banking, and COD options.',
  );
}
