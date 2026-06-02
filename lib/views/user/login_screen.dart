import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Login',
    icon: Icons.phone_android,
    description: 'Mobile number login with OTP and JWT session.',
  );
}
