import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'admin/admin_dashboard_screen.dart';
import '../features/delivery/screens/delivery_home_screen.dart';
import '../providers/app_state.dart';
import 'delivery/delivery_login_screen.dart';
import 'vendor/vendor_login_screen.dart';
import 'vendor/vendor_register_screen.dart';
import 'super_admin/super_admin_login_screen.dart';
import 'super_admin/super_admin_dashboard_screen.dart';
import 'user/user_home_screen.dart';

class SelectRoleScreen extends StatefulWidget {
  const SelectRoleScreen({super.key});

  static const routeName = '/select-role';

  @override
  State<SelectRoleScreen> createState() => _SelectRoleScreenState();
}

class _SelectRoleScreenState extends State<SelectRoleScreen> {
  bool _redirecting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    if (_redirecting ||
        !state.initialized ||
        !state.signedIn ||
        state.user == null) {
      return;
    }
    _redirecting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = switch (state.user!.role) {
        'delivery_person' => const DeliveryHomeScreen(),
        'vendor' => const AdminDashboardScreen(),
        'admin' => const AdminDashboardScreen(),
        'super_admin' => const SuperAdminDashboardScreen(),
        _ => const UserHomeScreen(),
      };
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => target),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14532D), Color(0xFF0F9D58)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose your login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Open the right dashboard for customer, delivery, vendor, or super admin access.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                title: 'Customer Login',
                subtitle:
                    'Browse products, place orders, and track deliveries.',
                icon: Icons.shopping_bag_rounded,
                color: const Color(0xFF0F9D58),
                onTap: () => Navigator.pushNamed(context, '/login'),
              ),
              _RoleCard(
                title: 'Delivery Login',
                subtitle:
                    'View assigned orders, update status, and manage earnings.',
                icon: Icons.delivery_dining_rounded,
                color: const Color(0xFF2563EB),
                onTap: () =>
                    Navigator.pushNamed(context, DeliveryLoginScreen.routeName),
              ),
              _RoleCard(
                title: 'Vendor Login',
                subtitle:
                    'Submit your store for approval or manage your store after approval.',
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFFEA580C),
                onTap: () =>
                    Navigator.pushNamed(context, VendorLoginScreen.routeName),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      VendorRegisterScreen.routeName,
                    ),
                    icon: const Icon(Icons.app_registration_rounded),
                    label: const Text('Register as Vendor'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: const Color(0xFFEA580C),
                      side: const BorderSide(color: Color(0xFFEA580C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
              ),
              _RoleCard(
                title: 'Super Admin Login',
                subtitle:
                    'Access platform-wide settings, analytics, and audit logs.',
                icon: Icons.verified_user_rounded,
                color: const Color(0xFF7C3AED),
                onTap: () => Navigator.pushNamed(
                  context,
                  SuperAdminLoginScreen.routeName,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF667064),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
