import 'package:flutter/material.dart';

import 'admin/admin_login_screen.dart';
import 'delivery/delivery_login_screen.dart';
import 'super_admin/super_admin_login_screen.dart';
import 'user/login_screen.dart';

class SelectRoleScreen extends StatelessWidget {
  const SelectRoleScreen({super.key});

  static const routeName = '/select-role';

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
                      'Open the right dashboard for customer, delivery, admin, or super admin access.',
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
                onTap: () =>
                    Navigator.pushNamed(context, LoginScreen.routeName),
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
                title: 'Admin Login',
                subtitle:
                    'Manage orders, products, customers, and delivery staff.',
                icon: Icons.admin_panel_settings_rounded,
                color: const Color(0xFFEA580C),
                onTap: () =>
                    Navigator.pushNamed(context, AdminLoginScreen.routeName),
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
