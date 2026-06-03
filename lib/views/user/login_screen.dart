import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/custom_text_field.dart';
import '../app_page.dart';
import 'profile_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await context.read<AppState>().login(
            phone: _phoneController.text.trim(),
            password: _passwordController.text,
          );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, ProfileScreen.routeName);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Login',
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text('Sign in to access your profile and orders.'),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone number',
                    keyboardType: TextInputType.phone,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Enter your phone number'
                            : null,
                  ),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    obscureText: true,
                    validator: (value) =>
                        (value == null || value.isEmpty)
                            ? 'Enter your password'
                            : null,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Signing in...' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      SignupScreen.routeName,
                    ),
                    child: const Text('Create a new account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
