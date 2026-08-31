import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/validators.dart';
import '../../providers/app_state.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/toast_widget.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  static const routeName = '/signup';

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressLabelController = TextEditingController(text: 'Home');
  final _addressLine1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressLabelController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final email = _emailController.text.trim().toLowerCase();
      final phone = Validators.normalizePhone(_phoneController.text);
      await context.read<AppState>().register(
        name: _nameController.text.trim(),
        phone: phone,
        email: email,
        password: _passwordController.text,
        addressLabel: _addressLabelController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        city: _cityController.text.trim(),
        pincode: _pincodeController.text.trim(),
      );
      if (!mounted) return;
      showToast(context, 'Account created successfully');
      Navigator.pushReplacementNamed(context, ProfileScreen.routeName);
    } catch (error) {
      if (!mounted) return;
      showToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF8E8), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            children: [
              const SizedBox(height: 20),
              _HeroCard(
                title: 'Create your Doormart account',
                subtitle:
                    'Save addresses, track deliveries, and reorder faster.',
                icon: Icons.person_add_alt_1_rounded,
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile details',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _nameController,
                          label: 'Full name',
                          icon: Icons.person_rounded,
                          validator: (value) => Validators.name(value),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _phoneController,
                          label: 'Phone number',
                          icon: Icons.phone_iphone_rounded,
                          keyboardType: TextInputType.phone,
                          validator: (value) => Validators.phone(value),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email address',
                          icon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => Validators.email(value),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_rounded,
                          obscureText: true,
                          validator: (value) => Validators.password(
                            value,
                            minLength: 6,
                            lengthMessage: 'Use at least 6 characters',
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Delivery address',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          controller: _addressLabelController,
                          label: 'Address label',
                          icon: Icons.home_rounded,
                          validator: (value) => Validators.requiredText(
                            value,
                            message: 'Enter address label',
                          ),
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _addressLine1Controller,
                          label: 'Flat, house no., street',
                          icon: Icons.location_on_rounded,
                          validator: (value) => Validators.requiredText(
                            value,
                            message: 'Enter your address',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _cityController,
                                label: 'City',
                                icon: Icons.location_city_rounded,
                                validator: (value) => Validators.requiredText(
                                  value,
                                  message: 'Enter your city',
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomTextField(
                                controller: _pincodeController,
                                label: 'Pincode',
                                icon: Icons.local_post_office_rounded,
                                keyboardType: TextInputType.number,
                                validator: (value) => Validators.pincode(value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _loading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF0F9D58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              _loading
                                  ? 'Creating account...'
                                  : 'Create account',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              LoginScreen.routeName,
                            ),
                            child: const Text('Already have an account? Login'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
