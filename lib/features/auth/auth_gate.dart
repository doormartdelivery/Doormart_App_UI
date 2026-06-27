import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../features/delivery/screens/delivery_home_screen.dart';
import '../../views/user/user_home_screen.dart';
import '../../views/select_role_screen.dart';
import '../../views/admin/admin_dashboard_screen.dart';
import '../../views/super_admin/super_admin_dashboard_screen.dart';
import '../../core/constants.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  static const routeName = '/auth-gate';

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  Widget? _target;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _validate();
  }

  Future<void> _validate() async {
    if (!_checking) return;
    final state = context.read<AppState>();
    try {
      if (!state.initialized) {
        await Future.doWhile(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return !state.initialized;
        });
      }
      final savedRole = state.user?.role;
      if (state.token != null && savedRole != UserRoles.deliveryPerson) {
        await state.refreshProfile();
      }
      final role = state.user?.role ?? savedRole;
      _target = switch (role) {
        UserRoles.deliveryPerson => const DeliveryHomeScreen(),
        UserRoles.admin => const AdminDashboardScreen(),
        UserRoles.superAdmin => const SuperAdminDashboardScreen(),
        UserRoles.user => const UserHomeScreen(),
        _ => null,
      };
    } catch (_) {
      await state.logout();
      _target = null;
    } finally {
      if (!mounted) return;
      setState(() => _checking = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_target == null) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            SelectRoleScreen.routeName,
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => _target!),
            (route) => false,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
