import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import 'admin_logout_confirm.dart';
import 'admin_dashboard_screen.dart';
import 'help_support_management_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'stock_screen.dart';
import '../super_admin/delivery_charges_screen.dart';
import '../super_admin/super_admin_vendors_screen.dart';
import '../super_admin/revenue_analytics_screen.dart';
import '../vendor/vendor_profile_screen.dart';

const _kBg = Color(0xFFF6F6F6);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF9E9E9E);
const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);

class AdminSidebarDrawer extends StatelessWidget {
  const AdminSidebarDrawer({
    super.key,
    required this.currentRoute,
    required this.onLogout,
  });

  final String currentRoute;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    // Watch the role so the menu rebuilds after the session/user profile has
    // finished loading. Using read here could leave Super Admin-only items
    // hidden until the drawer was opened again.
    final isSuperAdmin =
        context.watch<AppState>().user?.role == UserRoles.superAdmin;
    final menuTitle = isSuperAdmin ? 'Super Admin menu' : 'Vendor menu';
    final menuSubtitle = isSuperAdmin
        ? 'Navigate the super admin control center'
        : 'Navigate the vendor control center';
    final items = [
      (
        'Overview',
        Icons.dashboard,
        AdminDashboardScreen.routeName,
        const Color(0xFF0F766E),
      ),
      (
        'Orders',
        Icons.receipt_long,
        AdminOrdersScreen.routeName,
        const Color(0xFF0F766E),
      ),
      if (isSuperAdmin)
        (
          'Order analytics',
          Icons.analytics_outlined,
          RevenueAnalyticsScreen.routeName,
          const Color(0xFF7C3AED),
        ),
      if (!isSuperAdmin)
        (
          'Profile',
          Icons.badge_outlined,
          VendorProfileScreen.routeName,
          const Color(0xFF7C3AED),
        ),
      if (isSuperAdmin)
        (
          'Notifications',
          Icons.notifications_active,
          AdminNotificationsScreen.routeName,
          const Color(0xFFB45309),
        ),
      if (isSuperAdmin)
        (
          'Ticket Management',
          Icons.support_agent,
          HelpSupportManagementScreen.routeName,
          const Color(0xFFE8541A),
        ),
      (
        isSuperAdmin ? 'Products' : 'My Products',
        Icons.inventory_2,
        ManageProductsScreen.routeName,
        const Color(0xFF2563EB),
      ),
      if (isSuperAdmin)
        (
          'Categories',
          Icons.category,
          ManageCategoriesScreen.routeName,
          const Color(0xFF059669),
        ),
      if (isSuperAdmin)
        (
          'Banners',
          Icons.slideshow,
          ManageBannersScreen.routeName,
          const Color(0xFFEA580C),
        ),
      if (isSuperAdmin)
        (
          'Users',
          Icons.groups,
          ManageUsersScreen.routeName,
          const Color(0xFF7C3AED),
        ),
      if (isSuperAdmin)
        (
          'Vendors',
          Icons.storefront,
          SuperAdminVendorsScreen.routeName,
          const Color(0xFF0F766E),
        ),
      if (isSuperAdmin)
        (
          'Delivery partners',
          Icons.delivery_dining,
          ManageDeliveryScreen.routeName,
          const Color(0xFFDB2777),
        ),
      if (isSuperAdmin)
        (
          'Delivery charges',
          Icons.local_shipping_outlined,
          DeliveryChargesScreen.routeName,
          const Color(0xFFE8541A),
        ),
      (
        'Stock alerts',
        Icons.warning_amber,
        StockScreen.routeName,
        const Color(0xFFDC2626),
      ),
    ];

    return Drawer(
      child: Container(
        color: _kBg,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _kOrangeLight,
                      child: Icon(Icons.admin_panel_settings, color: _kOrange),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menuTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _kTextDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            menuSubtitle,
                            style: TextStyle(color: _kTextMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE7E7E7)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final selected = item.$3 == currentRoute;
                    final accent = item.$4;
                    return Material(
                      color: _kCard,
                      borderRadius: BorderRadius.circular(18),
                      elevation: selected ? 2 : 0,
                      shadowColor: Colors.black.withValues(alpha: 0.06),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context);
                          if (item.$3 != currentRoute) {
                            Navigator.pushReplacementNamed(context, item.$3);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(item.$2, color: accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.$1,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: selected ? accent : _kTextDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.$1 == 'Overview'
                                          ? 'Back to dashboard'
                                          : item.$1 == 'Ticket Management'
                                          ? 'Manage user tickets'
                                          : item.$1 == 'My Products'
                                          ? 'Manage your catalog'
                                          : item.$1 == 'Profile'
                                          ? 'Shop banner and business details'
                                          : 'Open section',
                                      style: const TextStyle(
                                        color: _kTextMid,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: selected ? accent : _kTextMid,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final navigator = Navigator.of(
                        context,
                        rootNavigator: true,
                      );
                      if (!await confirmAdminLogout(context)) return;
                      if (navigator.canPop()) {
                        navigator.pop();
                      }
                      await onLogout();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kOrange,
                      side: const BorderSide(color: _kOrange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: _kOrangeLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w800),
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
