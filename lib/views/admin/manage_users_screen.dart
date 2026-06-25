import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import '../app_page.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  static const routeName = '/admin/users';

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<UserModel>> _usersFuture;
  String _query = '';
  final Set<String> _updatingUsers = {};
  String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _filterOptions = [
    'All',
    'Active',
    'Blocked',
    'Admin',
    'Delivery',
    'Customer'
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
        if (_selectedFilter == 'Active') {
          return user.status.toLowerCase() == 'active';
        } else if (_selectedFilter == 'Blocked') {
          return user.status.toLowerCase() == 'blocked';
        } else {
          return user.role == _selectedFilter.toLowerCase();
        }
      }).toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.name.toLowerCase().contains(query) ||
            user.phone.toLowerCase().contains(query) ||
            (user.email ?? '').toLowerCase().contains(query) ||
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
      _showSnackBar(error.message, Icons.error_outline, const Color(0xFFBE123C));
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

  Future<void> _toggleBlock(UserModel user) async {
    final nextStatus =
        user.status.toLowerCase() == 'active' ? 'blocked' : 'active';
    setState(() => _updatingUsers.add(user.id));
    try {
      await context.read<AppState>().updateAdminUser(
            userId: user.id,
            status: nextStatus,
          );
      if (!mounted) return;
      _showSnackBar(
        nextStatus == 'blocked' ? '${user.name} blocked' : '${user.name} unblocked',
        nextStatus == 'blocked' ? Icons.block : Icons.verified_user,
        nextStatus == 'blocked' ? const Color(0xFFB45309) : const Color(0xFF0F3D31),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnackBar(error.message, Icons.error_outline, const Color(0xFFBE123C));
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
      _showSnackBar(error.message, Icons.error_outline, const Color(0xFFBE123C));
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingUsers.remove(user.id);
        _usersFuture = _loadUsers();
      });
    }
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
    return AppPage(
      title: 'Manage Users',
      actions: [
        IconButton(
          tooltip: 'Refresh users',
          onPressed: () {
            setState(() => _usersFuture = _loadUsers());
            _animationController.reset();
            _animationController.forward();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      children: [
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
                    onSearchChanged: (value) => setState(() => _query = value),
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
                  _UsersTable(
                    users: filteredUsers,
                    totalUsers: users.length,
                    updatingUserIds: _updatingUsers,
                    canAssignSuperAdmin: canAssignSuperAdmin,
                    onRoleChanged: _assignRole,
                    onEdit: _editUser,
                    onToggleBlock: _toggleBlock,
                    onDelete: _deleteUser,
                  ),
                ],
              ),
            );
          },
        ),
      ],
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
    final admins = users.where((user) => user.role == UserRoles.admin).length;
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F3D31), Color(0xFF176B52)],
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
                  color: const Color(0xFF4ADE80),
                ),
                _SummaryPill(
                  label: 'Blocked',
                  value: blocked,
                  icon: Icons.block_outlined,
                  color: const Color(0xFFF87171),
                ),
                _SummaryPill(
                  label: 'Admins',
                  value: admins,
                  icon: Icons.admin_panel_settings_outlined,
                  color: const Color(0xFFA78BFA),
                ),
                _SummaryPill(
                  label: 'Super Admins',
                  value: superAdmins,
                  icon: Icons.workspace_premium_outlined,
                  color: const Color(0xFF34D399),
                ),
                _SummaryPill(
                  label: 'Delivery',
                  value: delivery,
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFF472B6),
                ),
                _SummaryPill(
                  label: 'Customers',
                  value: customers,
                  icon: Icons.person_outline,
                  color: const Color(0xFF60A5FA),
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
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
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
                    color: Colors.white.withValues(alpha: 0.8),
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.04),
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
                    color: Color(0xFF64748B),
                    size: 22,
                  ),
                  suffixIcon: onClear == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                          onPressed: onClear,
                        ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: selectedFilter,
                underline: const SizedBox(),
                icon: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF0F3D31),
                  size: 24,
                ),
                style: const TextStyle(
                  color: Color(0xFF0F3D31),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                borderRadius: BorderRadius.circular(12),
                items: filterOptions.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(filter),
                  );
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.04),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
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
                headingRowColor:
                    WidgetStatePropertyAll(const Color(0xFFF8FAFC)),
                dataRowMinHeight: 76,
                dataRowMaxHeight: 88,
                horizontalMargin: 24,
                columnSpacing: 32,
                headingTextStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF475569),
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                columns: const [
                  DataColumn(label: Text('USER')),
                  DataColumn(label: Text('CONTACT')),
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
                                      Color(0xFF0F3D31)),
                                ),
                              )
                            : _RoleSelector(
                                value: user.role,
                                canAssignSuperAdmin: canAssignSuperAdmin,
                                onChanged: (role) =>
                                    onRoleChanged(user, role),
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
                                      Color(0xFF0F3D31)),
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
                                    tooltip: user.status.toLowerCase() ==
                                            'active'
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
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
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
          colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.06)],
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
    final bgColor = isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);

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
        color: const Color(0xFFF1F5F9),
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 72,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                  ),
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
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ],
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await context.read<AppState>().updateAdminUser(
            userId: widget.user.id,
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            email: _emailController.text.trim(),
            role: _role,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  colors: [Color(0xFF0F3D31), Color(0xFF176B52)],
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
                          horizontal: 16, vertical: 16),
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          child: Opacity(
            opacity: value,
            child: child,
          ),
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
            const Icon(
              Icons.error_outline,
              size: 56,
              color: Color(0xFFBE123C),
            ),
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
      return 'Admin';
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