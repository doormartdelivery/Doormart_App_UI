import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});
  static const routeName = '/otp';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'OTP Verification',
    icon: Icons.pin,
    description: 'Six digit OTP, resend timer, and verify action.',
  );
}
