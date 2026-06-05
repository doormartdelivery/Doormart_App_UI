import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/role_access.dart';
import '../providers/app_state.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/toast_widget.dart';

class RoleLoginScreen extends StatefulWidget {
  const RoleLoginScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.role,
    this.allowOtp = false,
    this.allowPhonePassword = true,
    this.allowEmailPassword = false,
  });

  final String title;
  final String subtitle;
  final String role;
  final bool allowOtp;
  final bool allowPhonePassword;
  final bool allowEmailPassword;

  @override
  State<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends State<RoleLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;

  bool get _useEmailOnly =>
      widget.allowEmailPassword && !widget.allowPhonePassword;
  bool get _usePhoneOrEmail =>
      widget.allowEmailPassword && widget.allowPhonePassword;
  String get _passwordIdentifier =>
      (_useEmailOnly ? _emailController : _phoneController).text.trim();
  bool get _passwordIdentifierIsEmail => _passwordIdentifier.contains('@');
  String get _otpTarget => _emailController.text.trim();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _loginWithPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final useEmail =
          _useEmailOnly || (_usePhoneOrEmail && _passwordIdentifierIsEmail);
      await context.read<AppState>().loginWithPassword(
        phone: useEmail ? null : _passwordIdentifier,
        email: useEmail ? _passwordIdentifier : null,
        password: _passwordController.text,
      );
      await _handlePostLogin();
    } catch (error) {
      if (!mounted) return;
      showToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtp() async {
    if (_otpTarget.isEmpty) {
      showToast(context, 'Enter email');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().sendOtp(email: _otpTarget);
      if (!mounted) return;
      setState(() => _otpSent = true);
      showToast(context, 'OTP sent to email');
    } catch (error) {
      if (!mounted) return;
      showToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if ((_otpController.text.trim()).isEmpty) {
      showToast(context, 'Enter OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().verifyOtp(
        email: _otpTarget,
        otp: _otpController.text.trim(),
      );
      await _handlePostLogin();
    } catch (error) {
      if (!mounted) return;
      showToast(context, error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handlePostLogin() async {
    if (!mounted) return;
    final appState = context.read<AppState>();
    if (appState.user?.role != widget.role) {
      await appState.logout();
      if (!mounted) return;
      showToast(context, 'This account cannot access ${widget.title}');
      return;
    }
    showToast(context, 'Logged in successfully');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      RoleAccess.dashboardForRole(appState.user?.role),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF4F8EC), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
            children: [
              const SizedBox(height: 20),
              _HeroCard(title: widget.title, subtitle: widget.subtitle),
              const SizedBox(height: 20),
              Card(
                elevation: 0,
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
                        if (_useEmailOnly)
                          CustomTextField(
                            controller: _emailController,
                            label: 'Email',
                            icon: Icons.email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Enter email'
                                : null,
                          )
                        else
                          CustomTextField(
                            controller: _phoneController,
                            label: _usePhoneOrEmail
                                ? 'Phone or email'
                                : 'Phone number',
                            icon: _usePhoneOrEmail
                                ? Icons.account_circle_rounded
                                : Icons.phone_iphone_rounded,
                            keyboardType: _usePhoneOrEmail
                                ? TextInputType.emailAddress
                                : TextInputType.phone,
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? (_usePhoneOrEmail
                                      ? 'Enter phone or email'
                                      : 'Enter phone number')
                                : null,
                          ),
                        const SizedBox(height: 12),
                        if (widget.allowPhonePassword ||
                            widget.allowEmailPassword)
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Password',
                            icon: Icons.lock_rounded,
                            obscureText: true,
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                ? 'Enter password'
                                : null,
                          ),
                        if (widget.allowOtp) ...[
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _otpController,
                            label: 'OTP',
                            icon: Icons.password_rounded,
                            keyboardType: TextInputType.number,
                          ),
                        ],
                        const SizedBox(height: 18),
                        if (widget.allowPhonePassword ||
                            widget.allowEmailPassword)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed: _loading ? null : _loginWithPassword,
                              child: Text(
                                _loading
                                    ? 'Signing in...'
                                    : 'Login with password',
                              ),
                            ),
                          ),
                        if (widget.allowOtp) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              onPressed: _loading
                                  ? null
                                  : (_otpSent ? _verifyOtp : _sendOtp),
                              child: Text(_otpSent ? 'Verify OTP' : 'Send OTP'),
                            ),
                          ),
                        ],
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
  const _HeroCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14532D), Color(0xFF0F9D58)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
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
    );
  }
}
