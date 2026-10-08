import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../../widgets/pagination_controls.dart';
import '../app_page.dart';
import 'admin_logout_confirm.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_products_screen.dart';
import 'stock_screen.dart';
import 'admin_sidebar_drawer.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  static const routeName = '/admin/users';

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late Future<List<UserModel>> _usersFuture;
  String _query = '';
  final Set<String> _updatingUsers = {};
  String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filterOptions = [
    'All',
    'Customer',
    'Delivery',
    'Vendor',
    'Superadmin',
  ];

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<List<UserModel>> _loadUsers() {
    return context.read<AppState>().adminUsers();
  }

  List<UserModel> _filteredUsers(List<UserModel> users) {
    final query = _query.trim().toLowerCase();
    var filtered = users;

    if (_selectedFilter != 'All') {
      filtered = filtered.where((user) {
        final filter = _selectedFilter.toLowerCase();
        return switch (filter) {
          'customer' => user.role == UserRoles.user,
          'delivery' => user.role == UserRoles.deliveryPerson,
          'vendor' => user.role == UserRoles.vendor,
          'superadmin' => user.role == UserRoles.superAdmin,
          _ => true,
        };
      }).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.phone.toLowerCase().contains(query) ||
            (user.email ?? '').toLowerCase().contains(query) ||
            user.vendorId.toLowerCase().contains(query) ||
            user.id.toLowerCase().contains(query) ||
            _roleLabel(user.role).toLowerCase().contains(query) ||
            user.status.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _assignRole(UserModel user, String role) async {
    setState(() => _updatingUsers.add(user.id));
    try {
      await context.read<AppState>().updateAdminUserRole(user.id, role);
      if (!mounted) return;
      _showSnackBar(
        '${user.name} access changed to ${_roleLabel(role)}',
        Icons.check_circle,
        const Color(0xFF0F3D31),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(
        error.message,
        Icons.error_outline,
        const Color(0xFFBE123C),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingUsers.remove(user.id);
        _usersFuture = _loadUsers();
      });
    }
  }

  Future<void> _editUser(UserModel user) async {
    final updated = await showDialog<UserModel?>(
      context: context,
      builder: (context) => _EditUserDialog(user: user),
    );
    if (!mounted || updated == null) return;
    _showSnackBar(
      '${updated.name} updated successfully',
      Icons.check_circle,
      const Color(0xFF0F3D31),
    );
    setState(() => _usersFuture = _loadUsers());
  }

  Future<void> _createUser() async {
    final created = await showDialog<UserModel?>(
      context: context,
      builder: (context) => const _CreateUserDialog(),
    );
    if (!mounted || created == null) return;
    _showSnackBar(
      '${created.name} created successfully',
      Icons.check_circle,
      const Color(0xFF0F3D31),
    );
    setState(() => _usersFuture = _loadUsers());
  }

  Future<void> _toggleBlock(UserModel user) async {
    final nextStatus = user.status.toLowerCase() == 'active'
        ? 'blocked'
        : 'active';
    setState(() => _updatingUsers.add(user.id));
    try {
      await context.read<AppState>().updateAdminUser(
        userId: user.id,
        status: nextStatus,
      );
      if (!mounted) return;
      _showSnackBar(
        nextStatus == 'blocked'
            ? '${user.name} blocked'
            : '${user.name} unblocked',
        nextStatus == 'blocked' ? Icons.block : Icons.verified_user,
        nextStatus == 'blocked'
            ? const Color(0xFFB45309)
            : const Color(0xFF0F3D31),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(
        error.message,
        Icons.error_outline,
        const Color(0xFFBE123C),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingUsers.remove(user.id);
        _usersFuture = _loadUsers();
      });
    }
  }

  Future<void> _deleteUser(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmationDialog(user: user),
    );
    if (confirmed != true) return;

    setState(() => _updatingUsers.add(user.id));
    try {
      await context.read<AppState>().deleteAdminUser(user.id);
      if (!mounted) return;
      _showSnackBar(
        '${user.name} deleted successfully',
        Icons.delete,
        const Color(0xFFBE123C),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(
        error.message,
        Icons.error_outline,
        const Color(0xFFBE123C),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingUsers.remove(user.id);
        _usersFuture = _loadUsers();
      });
    }
  }

  Future<void> _refreshUsers() async {
    setState(() => _usersFuture = _loadUsers());
    _animationController
      ..reset()
      ..forward();
    await _usersFuture;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Users refreshed from backend'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF6F6F6),
      drawer: AdminSidebarDrawer(
        currentRoute: ManageUsersScreen.routeName,
        onLogout: () async {
          if (!await confirmAdminLogout(context)) return;
          Navigator.pop(context);
          final logoutRoute = context.read<AppState>().logoutRouteName;
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            logoutRoute,
            (route) => false,
          );
        },
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            _UsersHero(onRefresh: _refreshUsers, onAdd: _createUser),
            const SizedBox(height: 16),
            FutureBuilder<List<UserModel>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _UsersError(message: snapshot.error.toString());
                }
                if (!snapshot.hasData) {
                  return const _LoadingSkeleton();
                }

                final users = snapshot.data!;
                final filteredUsers = _filteredUsers(users);
                final currentRole = context.read<AppState>().user?.role;
                final canAssignSuperAdmin = currentRole == UserRoles.superAdmin;

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UsersSummary(users: users),
                      const SizedBox(height: 20),
                      _SearchAndFilterBar(
                        controller: _searchController,
                        onSearchChanged: (value) =>
                            setState(() => _query = value),
                        onClear: _query.isEmpty
                            ? null
                            : () {
                                _searchController.clear();
                                setState(() => _query = '');
                              },
                        selectedFilter: _selectedFilter,
                        filterOptions: _filterOptions,
                        onFilterChanged: (filter) =>
                            setState(() => _selectedFilter = filter),
                      ),
                      const SizedBox(height: 16),
                      PaginatedCollection<UserModel>(
                        items: filteredUsers,
                        builder: (visibleUsers) => _UsersTable(
                          users: visibleUsers,
                          totalUsers: users.length,
                          updatingUserIds: _updatingUsers,
                          canAssignSuperAdmin: canAssignSuperAdmin,
                          onRoleChanged: _assignRole,
                          onEdit: _editUser,
                          onToggleBlock: _toggleBlock,
                          onDelete: _deleteUser,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersHero extends StatelessWidget {
  const _UsersHero({required this.onRefresh, required this.onAdd});

  final Future<void> Function() onRefresh;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 14,
              left: 14,
              child: Builder(
                builder: (menuContext) => IconButton.filledTonal(
                  onPressed: () => Scaffold.of(menuContext).openDrawer(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFF0EB),
                    foregroundColor: const Color(0xFFE8541A),
                  ),
                  icon: const Icon(Icons.menu),
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: onAdd,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0F3D31),
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Add user',
                    icon: const Icon(Icons.person_add_alt_1),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onRefresh,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFF0EB),
                      foregroundColor: const Color(0xFFE8541A),
                    ),
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Users',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Control access, roles, and user records from one polished panel.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.onNavigate, required this.onLogout});

  final void Function(String route) onNavigate;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.read<AppState>().user?.role == UserRoles.superAdmin;
    final items = [
      ('Overview', Icons.dashboard, AdminDashboardScreen.routeName),
      ('Orders', Icons.receipt_long, AdminOrdersScreen.routeName),
      if (isSuperAdmin)
        (
          'Notifications',
          Icons.notifications_active,
          AdminNotificationsScreen.routeName,
        ),
      ('Products', Icons.inventory_2, ManageProductsScreen.routeName),
      if (isSuperAdmin)
        ('Categories', Icons.category, ManageCategoriesScreen.routeName),
      if (isSuperAdmin)
        ('Banners', Icons.slideshow, ManageBannersScreen.routeName),
      if (isSuperAdmin) ('Users', Icons.groups, ManageUsersScreen.routeName),
      if (isSuperAdmin)
        (
          'Delivery partners',
          Icons.delivery_dining,
          ManageDeliveryScreen.routeName,
        ),
      ('Stock alerts', Icons.warning_amber, StockScreen.routeName),
    ];

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Color(0xFFFFF0EB),
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Color(0xFFE8541A),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vendor menu',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Navigate the control center',
                          style: TextStyle(color: Color(0xFF9E9E9E)),
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
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final accentColors = const [
                    Color(0xFF0F766E),
                    Color(0xFFB45309),
                    Color(0xFF2563EB),
                    Color(0xFF059669),
                    Color(0xFFEA580C),
                    Color(0xFF7C3AED),
                    Color(0xFFDB2777),
                    Color(0xFFDC2626),
                  ];
                  final accent = accentColors[index % accentColors.length];
                  return Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => onNavigate(item.$3),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE8541A,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                item.$2,
                                color: const Color(0xFFE8541A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.$1,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.$1 == 'Overview'
                                        ? 'Back to dashboard'
                                        : 'Open section',
                                    style: const TextStyle(
                                      color: Color(0xFF9E9E9E),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF9E9E9E),
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
                child: FilledButton.icon(
                  onPressed: onLogout,
                  style: FilledButton.styleFrom(
                    foregroundColor: const Color(0xFFE8541A),
                    backgroundColor: const Color(0xFFFFF0EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F3D31)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(5, (index) => _SkeletonRow()),
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _ShimmerCircle(),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ShimmerLine(width: 120),
                  SizedBox(height: 6),
                  _ShimmerLine(width: 80),
                ],
              ),
            ),
            _ShimmerLine(width: 80),
            SizedBox(width: 16),
            _ShimmerLine(width: 60),
            SizedBox(width: 16),
            _ShimmerLine(width: 40),
          ],
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatelessWidget {
  const _ShimmerCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ShimmerLine extends StatelessWidget {
  const _ShimmerLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _UsersSummary extends StatelessWidget {
  const _UsersSummary({required this.users});

  final List<UserModel> users;

  @override
  Widget build(BuildContext context) {
    final vendors = users.where((user) => user.role == UserRoles.admin).length;
    final delivery = users
        .where((user) => user.role == UserRoles.deliveryPerson)
        .length;
    final customers = users.where((user) => user.role == UserRoles.user).length;
    final superAdmins = users
        .where((user) => user.role == UserRoles.superAdmin)
        .length;
    final active = users
        .where((user) => user.status.toLowerCase() == 'active')
        .length;
    final blocked = users
        .where((user) => user.status.toLowerCase() == 'blocked')
        .length;

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8541A), Color(0xFFFF8A5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F3D31).withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Directory',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage access, account details and user status across your platform.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _SummaryPill(
                  label: 'Total',
                  value: users.length,
                  icon: Icons.people_alt_outlined,
                  color: Colors.white,
                ),
                _SummaryPill(
                  label: 'Active',
                  value: active,
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFFFFF7F2),
                ),
                _SummaryPill(
                  label: 'Blocked',
                  value: blocked,
                  icon: Icons.block_outlined,
                  color: const Color(0xFFFFE0D4),
                ),
                _SummaryPill(
                  label: 'Vendors',
                  value: vendors,
                  icon: Icons.admin_panel_settings_outlined,
                  color: const Color(0xFFFFE8DD),
                ),
                _SummaryPill(
                  label: 'Super Admins',
                  value: superAdmins,
                  icon: Icons.workspace_premium_outlined,
                  color: const Color(0xFFFFF0E8),
                ),
                _SummaryPill(
                  label: 'Delivery',
                  value: delivery,
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFFFE9DB),
                ),
                _SummaryPill(
                  label: 'Customers',
                  value: customers,
                  icon: Icons.person_outline,
                  color: const Color(0xFFFFF7F2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  '$value',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.onSearchChanged,
    required this.onClear,
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onClear;
  final String selectedFilter;
  final List<String> filterOptions;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1D4C8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8541A).withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search users by name, phone, email, or ID...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFFE8541A),
                    size: 22,
                  ),
                  suffixIcon: onClear == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFE8541A),
                          ),
                          onPressed: onClear,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            Container(height: 40, width: 1, color: const Color(0xFFF1D4C8)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: selectedFilter,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.filter_list,
                  color: Color(0xFFE8541A),
                  size: 24,
                ),
                style: const TextStyle(
                  color: Color(0xFFE8541A),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                borderRadius: BorderRadius.circular(12),
                items: filterOptions.map((filter) {
                  return DropdownMenuItem(value: filter, child: Text(filter));
                }).toList(),
                onChanged: (value) {
                  if (value != null) onFilterChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.totalUsers,
    required this.updatingUserIds,
    required this.canAssignSuperAdmin,
    required this.onRoleChanged,
    required this.onEdit,
    required this.onToggleBlock,
    required this.onDelete,
  });

  final List<UserModel> users;
  final int totalUsers;
  final Set<String> updatingUserIds;
  final bool canAssignSuperAdmin;
  final void Function(UserModel user, String role) onRoleChanged;
  final Future<void> Function(UserModel user) onEdit;
  final Future<void> Function(UserModel user) onToggleBlock;
  final Future<void> Function(UserModel user) onDelete;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _EmptyState();
    }

    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1D4C8)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8541A).withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  Text(
                    'All Users',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                      fontSize: 18,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE8541A), Color(0xFFFF8A5C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${users.length} of $totalUsers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${users.length} users',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(
                  Color(0xFFFFF7F2),
                ),
                dataRowMinHeight: 76,
                dataRowMaxHeight: 88,
                horizontalMargin: 24,
                columnSpacing: 32,
                headingTextStyle: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFE8541A),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                columns: const [
                  DataColumn(label: Text('USER')),
                  DataColumn(label: Text('CONTACT')),
                  DataColumn(label: Text('VENDOR')),
                  DataColumn(label: Text('ACCESS ROLE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('JOINED')),
                  DataColumn(label: Text('ASSIGN ROLE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: users.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final updating = updatingUserIds.contains(user.id);
                  return DataRow(
                    cells: [
                      DataCell(_UserIdentity(user: user)),
                      DataCell(_ContactDetails(user: user)),
                      DataCell(_VendorBadge(vendorId: user.vendorId)),
                      DataCell(_RoleBadge(role: user.role)),
                      DataCell(_StatusBadge(status: user.status)),
                      DataCell(Text(_formatDate(user.createdAt))),
                      DataCell(
                        updating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0F3D31),
                                  ),
                                ),
                              )
                            : _RoleSelector(
                                value: user.role,
                                canAssignSuperAdmin: canAssignSuperAdmin,
                                onChanged: (role) => onRoleChanged(user, role),
                              ),
                      ),
                      DataCell(
                        updating
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF0F3D31),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ActionButton(
                                    tooltip: 'Edit user',
                                    icon: Icons.edit_outlined,
                                    color: const Color(0xFF2563EB),
                                    onPressed: () => onEdit(user),
                                  ),
                                  _ActionButton(
                                    tooltip:
                                        user.status.toLowerCase() == 'active'
                                        ? 'Block user'
                                        : 'Unblock user',
                                    icon: user.status.toLowerCase() == 'active'
                                        ? Icons.block_outlined
                                        : Icons.verified_user_outlined,
                                    color: user.status.toLowerCase() == 'active'
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF15803D),
                                    onPressed: () => onToggleBlock(user),
                                  ),
                                  _ActionButton(
                                    tooltip: 'Delete user',
                                    icon: Icons.delete_outline,
                                    color: const Color(0xFFBE123C),
                                    onPressed: () => onDelete(user),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0.8, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            color: color,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          ),
        ),
      ),
    );
  }
}

class _UserIdentity extends StatelessWidget {
  const _UserIdentity({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final initial = user.name.trim().isEmpty
        ? '?'
        : user.name.trim().substring(0, 1).toUpperCase();
    final color = _roleColor(user.role);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ID: ${user.id.substring(0, 8)}...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactDetails extends StatelessWidget {
  const _ContactDetails({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.phone, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              user.phone.isEmpty ? '-' : user.phone,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.email, size: 14, color: Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              user.email?.isNotEmpty == true ? user.email! : '-',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}

class _VendorBadge extends StatelessWidget {
  const _VendorBadge({required this.vendorId});

  final String vendorId;

  @override
  Widget build(BuildContext context) {
    final isMain = vendorId.toLowerCase() == 'main';
    final color = isMain ? const Color(0xFF0F766E) : const Color(0xFF7C3AED);
    final bgColor = isMain ? const Color(0xFFCCFBF1) : const Color(0xFFEDE9FE);
    final displayId = isMain ? 'Main' : _formatVendorDisplayId(vendorId, null);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 15, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              displayId,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatVendorDisplayId(String? vendorId, String? id) {
  final normalized = (vendorId ?? '').trim();
  final upper = normalized.toUpperCase();
  if (upper.startsWith('DMD-VENDOR-')) return upper;

  final source = (id ?? normalized).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  if (source.isEmpty) return 'DMD-VENDOR-0000';
  final suffix = source.length >= 4
      ? source.substring(source.length - 4)
      : source.padLeft(4, '0');
  return 'DMD-VENDOR-${suffix.toUpperCase()}';
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            color.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            _roleLabel(role),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status.toLowerCase() == 'active';
    final color = isActive ? const Color(0xFF15803D) : const Color(0xFFB45309);
    final bgColor = isActive
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEF3C7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _titleCase(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.value,
    required this.canAssignSuperAdmin,
    required this.onChanged,
  });

  final String value;
  final bool canAssignSuperAdmin;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final roles = _assignableRoles.where((role) {
      return role != UserRoles.superAdmin ||
          canAssignSuperAdmin ||
          value == UserRoles.superAdmin;
    }).toList();
    final safeValue = roles.contains(value) ? value : UserRoles.user;
    final lockedSuperAdmin =
        value == UserRoles.superAdmin && !canAssignSuperAdmin;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3EC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          borderRadius: BorderRadius.circular(10),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: roles.map((role) {
            return DropdownMenuItem(
              value: role,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(_roleLabel(role)),
              ),
            );
          }).toList(),
          onChanged: lockedSuperAdmin
              ? null
              : (role) {
                  if (role != null && role != value) onChanged(role);
                },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1D4C8)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: const Color(0xFFE8541A)),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Color(0xFFBE123C),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Delete User',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      content: Text(
        'Delete ${user.name}? This action cannot be undone. All associated data will be permanently removed from the system.',
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: Color(0xFF475569),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Cancel',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFBE123C),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ],
    );
  }
}

class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _vendorIdController = TextEditingController();
  late String _role;
  late String _status;
  bool _saving = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  static const _createRoles = [
    UserRoles.user,
    UserRoles.deliveryPerson,
    UserRoles.admin,
  ];

  @override
  void initState() {
    super.initState();
    _role = UserRoles.admin;
    _status = 'active';
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _vendorIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and phone number are required'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final vendorId = _vendorIdController.text.trim();
      final created = await context.read<AppState>().createAdminUser(
        name: name,
        phone: phone,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _role,
        status: _status,
        vendorId: vendorId.isEmpty ? null : vendorId,
      );
      if (!mounted) return;
      Navigator.pop(context, created);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(error.message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFBE123C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8541A), Color(0xFFFF8A5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_add_alt_1, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Text(
              'Add User',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Access Role',
                  icon: Icons.assignment_ind_outlined,
                  value: _role,
                  items: _createRoles,
                  itemLabel: _roleLabel,
                  onChanged: (value) {
                    if (value != null) setState(() => _role = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildDropdown(
                  label: 'Status',
                  icon: Icons.verified_user_outlined,
                  value: _status,
                  items: const ['active', 'blocked'],
                  itemLabel: _titleCase,
                  onChanged: (value) {
                    if (value != null) setState(() => _status = value);
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _vendorIdController,
                  label: 'Vendor ID',
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Leave empty to auto-generate a new vendor. Each vendor manages only products, orders and stock under its own vendor.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F3D31),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add_alt_1, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Create User',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required String Function(String) itemLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : items.first,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: _roleColor(item)),
                const SizedBox(width: 10),
                Text(itemLabel(item)),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  const _EditUserDialog({required this.user});

  final UserModel user;

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _vendorIdController;
  late String _role;
  bool _saving = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController = TextEditingController(text: widget.user.phone);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _vendorIdController = TextEditingController(text: widget.user.vendorId);
    _role = widget.user.role;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vendorIdController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final vendorId = _vendorIdController.text.trim();
      final updated = await context.read<AppState>().updateAdminUser(
        userId: widget.user.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        role: _role,
        vendorId: vendorId.isEmpty ? null : vendorId,
      );
      if (!mounted) return;
      Navigator.pop(context, updated);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(error.message)),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFBE123C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRole = context.read<AppState>().user?.role;
    final canAssignSuperAdmin = currentRole == UserRoles.superAdmin;
    final roles = _assignableRoles.where((role) {
      return role != UserRoles.superAdmin ||
          canAssignSuperAdmin ||
          _role == UserRoles.superAdmin;
    }).toList();

    return ScaleTransition(
      scale: _scaleAnimation,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8541A), Color(0xFFFF8A5C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.edit_outlined, color: Colors.white),
            ),
            const SizedBox(width: 16),
            const Text(
              'Edit User',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: roles.contains(_role) ? _role : UserRoles.user,
                    items: roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: _roleColor(role),
                            ),
                            const SizedBox(width: 10),
                            Text(_roleLabel(role)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _role = value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Access Role',
                      prefixIcon: const Icon(
                        Icons.assignment_ind_outlined,
                        color: Color(0xFF64748B),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _vendorIdController,
                  label: 'Vendor ID',
                  icon: Icons.storefront_outlined,
                ),
                const SizedBox(height: 8),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Each vendor manages only products, orders and stock under this vendor.',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F3D31),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.save_outlined, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFECDD3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFBE123C)),
            const SizedBox(height: 16),
            Text(
              'Error Loading Users',
              style: const TextStyle(
                color: Color(0xFFBE123C),
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF9F1239),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

const _assignableRoles = [
  UserRoles.user,
  UserRoles.deliveryPerson,
  UserRoles.admin,
  UserRoles.superAdmin,
];

String _roleLabel(String role) {
  switch (role) {
    case UserRoles.admin:
      return 'Vendor';
    case UserRoles.deliveryPerson:
      return 'Delivery';
    case UserRoles.superAdmin:
      return 'Super Admin';
    case UserRoles.user:
    default:
      return 'Customer';
  }
}

Color _roleColor(String role) {
  switch (role) {
    case UserRoles.admin:
      return const Color(0xFF7C3AED);
    case UserRoles.deliveryPerson:
      return const Color(0xFFDB2777);
    case UserRoles.superAdmin:
      return const Color(0xFF0F766E);
    case UserRoles.user:
    default:
      return const Color(0xFF2563EB);
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _titleCase(String value) {
  if (value.isEmpty) return '-';
  return value.substring(0, 1).toUpperCase() + value.substring(1).toLowerCase();
}
