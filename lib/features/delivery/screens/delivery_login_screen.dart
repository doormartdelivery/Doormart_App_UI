import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../services/api_service.dart';
import '../../../../models/user_model.dart';
import '../../../../providers/app_state.dart';
import '../../../../views/access_denied_screen.dart';
import '../providers/delivery_provider.dart';
import 'delivery_home_screen.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  static const routeName = '/delivery/login';

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text('Delivery Login', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _identifier,
                  decoration: const InputDecoration(labelText: 'Email or phone'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => (value == null || value.isEmpty) ? 'Enter email or phone' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading ? const CircularProgressIndicator() : const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final provider = context.read<DeliveryProvider>();
    try {
      final value = _identifier.text.trim();
      await provider.login(
        email: value.contains('@') ? value : null,
        phone: value.contains('@') ? null : value,
        password: _password.text.trim(),
      );
      if (!mounted) return;
      final appState = context.read<AppState>();
      final authUser = provider.authUser;
      if (authUser != null && provider.authToken != null) {
        appState.token = provider.authToken;
        appState.user = UserModel.fromJson(authUser);
        await appState.refreshProfile();
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(DeliveryHomeScreen.routeName);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 403) {
        Navigator.of(context).pushNamed(AccessDeniedScreen.routeName);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
