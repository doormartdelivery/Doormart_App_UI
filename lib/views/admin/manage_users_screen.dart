import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<UserModel>> _usersFuture;
  String _query = '';
  final Set<String> _updatingUsers = {};

  @override
  void initState() {
    super.initState();
    _usersFuture = _loadUsers();
  }

  Future<List<UserModel>> _loadUsers() {
    return context.read<AppState>().adminUsers();
  }

  List<UserModel> _filteredUsers(List<UserModel> users) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return users;

    return users.where((user) {
      return user.name.toLowerCase().contains(query) ||
          user.phone.toLowerCase().contains(query) ||
          (user.email ?? '').toLowerCase().contains(query) ||
          user.id.toLowerCase().contains(query) ||
          _roleLabel(user.role).toLowerCase().contains(query) ||
          user.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _assignRole(UserModel user, String role) async {
    setState(() => _updatingUsers.add(user.id));
    try {
      await context.read<AppState>().updateAdminUserRole(user.id, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} access changed to ${_roleLabel(role)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _updatingUsers.remove(user.id);
        _usersFuture = _loadUsers();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Manage users',
      actions: [
        IconButton(
          tooltip: 'Refresh users',
          onPressed: () => setState(() => _usersFuture = _loadUsers()),
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
            if (!snapshot.hasData) return const LinearProgressIndicator();

            final users = snapshot.data!;
            final filteredUsers = _filteredUsers(users);
            final currentRole = context.read<AppState>().user?.role;
            final canAssignSuperAdmin = currentRole == UserRoles.superAdmin;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _UsersSummary(users: users),
                const SizedBox(height: 14),
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: _query.isEmpty
                      ? null
                      : () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                ),
                const SizedBox(height: 14),
                _UsersTable(
                  users: filteredUsers,
                  updatingUserIds: _updatingUsers,
                  canAssignSuperAdmin: canAssignSuperAdmin,
                  onRoleChanged: _assignRole,
                ),
              ],
            );
          },
        ),
      ],
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF12372A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'User model records',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
      const SizedBox(height: 10),

      SizedBox(
        width: double.infinity,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryPill(label: 'Total users', value: users.length),
            _SummaryPill(label: 'Admins', value: admins),
            _SummaryPill(label: 'Super Admins', value: superAdmins),
            _SummaryPill(label: 'Delivery', value: delivery),
            _SummaryPill(label: 'Customers', value: customers),
          ],
        ),
      ),
    ],
  ),
),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$value $label',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search users by name, phone, email, id, role, or status',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear == null
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.updatingUserIds,
    required this.canAssignSuperAdmin,
    required this.onRoleChanged,
  });

  final List<UserModel> users;
  final Set<String> updatingUserIds;
  final bool canAssignSuperAdmin;
  final void Function(UserModel user, String role) onRoleChanged;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const _NoUsersFound();

    return LayoutBuilder(
      builder: (context, constraints) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingTextStyle: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
                columns: const [
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Contact')),
                  DataColumn(label: Text('Access role')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Joined')),
                  DataColumn(label: Text('Assign role')),
                ],
                rows: users.map((user) {
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
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _RoleSelector(
                                value: user.role,
                                canAssignSuperAdmin: canAssignSuperAdmin,
                                onChanged: (role) =>
                                    onRoleChanged(user, role),
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: _roleColor(user.role).withValues(alpha: 0.14),
          child: Text(
            initial,
            style: TextStyle(
              color: _roleColor(user.role),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              user.id,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
            ),
          ],
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
        Text(user.phone.isEmpty ? '-' : user.phone),
        Text(
          user.email?.isNotEmpty == true ? user.email! : '-',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          _roleLabel(role),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
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

    return Text(
      _titleCase(status),
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
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

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: safeValue,
        borderRadius: BorderRadius.circular(8),
        items: roles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Text(_roleLabel(role)),
          );
        }).toList(),
        onChanged: lockedSuperAdmin
            ? null
            : (role) {
                if (role != null && role != value) onChanged(role);
              },
      ),
    );
  }
}

class _NoUsersFound extends StatelessWidget {
  const _NoUsersFound();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No users found')),
      ),
    );
  }
}

class _UsersError extends StatelessWidget {
  const _UsersError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFBE123C),
            fontWeight: FontWeight.w800,
          ),
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
