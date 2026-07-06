import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/user_model.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import 'admin_logout_confirm.dart';
import 'admin_dashboard_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'stock_screen.dart';
import 'admin_sidebar_drawer.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kCard = Colors.white;
const _kBorder = Color(0xFFF1D4C8);
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF6B7280);

class ManageDeliveryScreen extends StatefulWidget {
  const ManageDeliveryScreen({super.key});
  static const routeName = '/admin/delivery';

  @override
  State<ManageDeliveryScreen> createState() => _ManageDeliveryScreenState();
}

class _ManageDeliveryScreenState extends State<ManageDeliveryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  // ── Local state — no Future needed ────────────────────────────────────────
  List<_DeliveryPartnerRow> _allPartners = [];
  bool _loading = true;
  String? _error;
  String _query = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await context.read<AppState>().adminUsers();
      final delivery = await context.read<AppState>().adminDeliveryPartners();
      if (!mounted) return;
      final deliveryByUserId = <String, Map<String, dynamic>>{
        for (final item in delivery)
          if (item['user'] is Map<String, dynamic>)
            (item['user']['_id'] as String? ??
                    item['user']['id'] as String? ??
                    ''):
                item,
      };
      setState(() {
        _allPartners = users
            .where((u) => u.role == UserRoles.deliveryPerson)
            .map(
              (u) => _DeliveryPartnerRow(
                user: u,
                isOnline: _isOnlineFromBackend(
                  user: u,
                  deliveryDoc: deliveryByUserId[u.id],
                ),
              ),
            )
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ── Filter / search ───────────────────────────────────────────────────────
  List<_DeliveryPartnerRow> get _filtered {
    var items = List<_DeliveryPartnerRow>.from(_allPartners);
    if (_filter != 'All') {
      items = items.where((u) => _statusLabel(u.user, isOnline: u.isOnline) == _filter).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      items = items.where((u) {
        return u.user.name.toLowerCase().contains(q) ||
            u.user.phone.toLowerCase().contains(q) ||
            u.user.id.toLowerCase().contains(q) ||
            (u.user.email ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return items;
  }

  // ── Add partner ───────────────────────────────────────────────────────────
  Future<void> _addPartner() async {
    final newUser = await showDialog<UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _PartnerDialog(),
    );
    if (newUser == null || !mounted) return;

    // Instantly add to local list — no full reload needed
    setState(
      () => _allPartners = [
        _DeliveryPartnerRow(user: newUser, isOnline: false),
        ..._allPartners,
      ],
    );
    _showSnack('${newUser.name} added');
  }

  // ── Edit partner ──────────────────────────────────────────────────────────
  Future<void> _editPartner(UserModel user) async {
    final updated = await showDialog<UserModel>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PartnerDialog(user: user),
    );
    if (updated == null || !mounted) return;

    // Replace in local list instantly
    setState(() {
      _allPartners = _allPartners.map((row) {
        return row.user.id == updated.id
            ? _DeliveryPartnerRow(user: updated, isOnline: row.isOnline)
            : row;
      }).toList();
    });
    _showSnack('${updated.name} updated');
  }

  // ── Delete partner ────────────────────────────────────────────────────────
  Future<void> _deletePartner(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDialog(name: user.name),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppState>().deleteAdminUser(user.id);
      if (!mounted) return;
      // Remove from local list instantly
      setState(() => _allPartners.removeWhere((row) => row.user.id == user.id));
      _showSnack('${user.name} removed');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Delete failed: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : _kOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _kBg,
      drawer: AdminSidebarDrawer(
        currentRoute: ManageDeliveryScreen.routeName,
        onLogout: () async {
          if (!await confirmAdminLogout(context)) return;
          Navigator.pop(context);
          await context.read<AppState>().logout();
          if (!context.mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        },
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _kOrange))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kOrange,
        onPressed: _addPartner,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text(
          'Add Partner',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  Widget _buildBody() {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final partners = _filtered;
    final total = _allPartners.length;
    final online =
        _allPartners.where((u) => _statusLabel(u.user, isOnline: u.isOnline) == 'Online').length;
    final offline =
        _allPartners.where((u) => _statusLabel(u.user, isOnline: u.isOnline) == 'Offline').length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 100 + bottomInset),
      children: [
        // ── Header ──────────────────────────────────────────────────────
        _Header(
          onMenu: () => _scaffoldKey.currentState?.openDrawer(),
          onRefresh: _load,
        ),

        const SizedBox(height: 16),

        // ── Stats row ────────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatCard(label: 'Total', value: '$total',
                  icon: Icons.groups_rounded, color: _kOrange),
              const SizedBox(width: 10),
              _StatCard(label: 'Online', value: '$online',
                  icon: Icons.wifi_rounded,
                  color: const Color(0xFF16A34A)),
              const SizedBox(width: 10),
              _StatCard(label: 'Offline', value: '$offline',
                  icon: Icons.wifi_off_rounded,
                  color: const Color(0xFF64748B)),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Search ───────────────────────────────────────────────────────
        TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search by name, ID, phone…',
            prefixIcon: const Icon(Icons.search_rounded, color: _kOrange),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: _kCard,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _kOrange, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Filter chips ─────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _Chip(label: 'All', selected: _filter == 'All',
                  onTap: () => setState(() => _filter = 'All')),
              const SizedBox(width: 8),
              _Chip(label: 'Online', selected: _filter == 'Online',
                  onTap: () => setState(() => _filter = 'Online')),
              const SizedBox(width: 8),
              _Chip(label: 'Offline', selected: _filter == 'Offline',
                  onTap: () => setState(() => _filter = 'Offline')),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Partner list ─────────────────────────────────────────────────
        if (partners.isEmpty)
          _EmptyState(onAdd: _addPartner)
        else
          ...partners.map(
            (u) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _PartnerCard(
                user: u.user,
                isOnline: u.isOnline,
                onEdit: () => _editPartner(u.user),
                onDelete: () => _deletePartner(u.user),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onMenu, required this.onRefresh});
  final VoidCallback onMenu;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMenu,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.menu_rounded, color: _kOrange),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Partners',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _kTextDark,
                  ),
                ),
                Text(
                  'Manage and track your delivery fleet',
                  style: TextStyle(fontSize: 12, color: _kTextMid),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.refresh_rounded, color: _kOrange),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kTextMid)),
        ],
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _kOrange : _kCard,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? _kOrange : _kBorder),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _kOrange.withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: selected ? Colors.white : _kTextDark,
          ),
        ),
      ),
    );
  }
}

// ─── Partner Card ─────────────────────────────────────────────────────────────

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.user,
    required this.isOnline,
    required this.onEdit,
    required this.onDelete,
  });
  final UserModel user;
  final bool isOnline;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(user, isOnline: isOnline);
    final vehicle = _vehicleFor(user);
    final statusColor = switch (status) {
      'Online' => const Color(0xFF16A34A),
      _ => const Color(0xFF64748B),
    };
    final statusBg = switch (status) {
      'Online' => const Color(0xFFECFDF5),
      _ => const Color(0xFFF1F5F9),
    };

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top: avatar + info + actions ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _kOrangeLight,
                      backgroundImage: user.avatarUrl.isNotEmpty
                          ? NetworkImage(user.avatarUrl)
                          : null,
                      child: user.avatarUrl.isEmpty
                          ? Text(
                              user.name.isNotEmpty
                                  ? user.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: _kOrange,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '#${user.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _kTextMid,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    _ActionBtn(
                      icon: Icons.edit_rounded,
                      color: _kOrange,
                      bg: _kOrangeLight,
                      tooltip: 'Edit partner',
                      onTap: onEdit,
                    ),
                    const SizedBox(height: 6),
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: const Color(0xFFDC2626),
                      bg: const Color(0xFFFFEEEE),
                      tooltip: 'Delete partner',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────
          const Divider(height: 1, color: Color(0xFFF5F5F5)),

          // ── Bottom: vehicle + phone + email ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                const Icon(Icons.electric_bike_rounded,
                    size: 16, color: _kTextMid),
                const SizedBox(width: 6),
                Text(vehicle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _kTextDark,
                    )),
                const SizedBox(width: 14),
                const Icon(Icons.phone_rounded,
                    size: 14, color: _kTextMid),
                const SizedBox(width: 4),
                Text(user.phone,
                    style: const TextStyle(
                        fontSize: 12, color: _kTextMid)),
                const Spacer(),
                if ((user.email ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.email!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bg,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final Color color, bg;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

// ─── Delete Dialog ────────────────────────────────────────────────────────────

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: const Icon(Icons.person_off_rounded,
          color: Color(0xFFDC2626), size: 44),
      title: const Text('Delete partner',
          style: TextStyle(fontWeight: FontWeight.w900)),
      content: Text('Remove "$name" from the delivery team?',
          textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          const Icon(Icons.delivery_dining_rounded,
              size: 56, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          const Text('No partners found',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _kTextMid,
                  fontSize: 16)),
          const SizedBox(height: 6),
          const Text('Add a delivery partner to get started',
              style: TextStyle(color: _kTextMid, fontSize: 13)),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _kOrange,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text('Add Partner',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: Color(0xFFDC2626)),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextMid)),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kOrange),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Partner Dialog ───────────────────────────────────────────────────────────
// KEY FIX: returns UserModel directly instead of bool
// Parent updates _allPartners instantly without reload

class _PartnerDialog extends StatefulWidget {
  const _PartnerDialog({this.user});
  final UserModel? user;

  @override
  State<_PartnerDialog> createState() => _PartnerDialogState();
}

class _PartnerDialogState extends State<_PartnerDialog> {
  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.user?.name ?? '');
  late final TextEditingController _phoneCtrl =
      TextEditingController(text: widget.user?.phone ?? '');
  late final TextEditingController _emailCtrl =
      TextEditingController(text: widget.user?.email ?? '');
  late final TextEditingController _avatarCtrl =
      TextEditingController(text: widget.user?.avatarUrl ?? '');
  late final TextEditingController _passwordCtrl = TextEditingController();

  Uint8List? _avatarBytes;
  bool _uploading = false;
  bool _saving = false;
  String? _uploadError;
  String? _saveError;

  bool get _isEdit => widget.user != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _avatarCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Pick & upload avatar ──────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    setState(() {
      _uploading = true;
      _uploadError = null;
    });
    try {
      final picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) {
        setState(() => _uploading = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      final url = await context.read<AppState>().uploadProductImage(
            picked.path,
            bytes: bytes,
            fileName: picked.name,
          );
      if (!mounted) return;
      setState(() {
        _avatarCtrl.text = url;
        _avatarBytes = bytes;
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError =
            'Upload failed: ${e.toString().replaceFirst('Exception: ', '')}';
        _uploading = false;
      });
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _saveError = 'Name is required');
      return;
    }
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _saveError = 'Phone is required');
      return;
    }
    if (_saving) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      final state = context.read<AppState>();
      UserModel saved;

      if (!_isEdit) {
        if (_passwordCtrl.text.trim().isEmpty) {
          setState(() => _saveError = 'Password is required');
          return;
        }
        saved = await state.createAdminUser(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          avatarUrl: _avatarCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
          role: UserRoles.deliveryPerson,
        );
      } else {
        saved = await state.updateAdminUser(
          userId: widget.user!.id,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          avatarUrl: _avatarCtrl.text.trim(),
          password: _passwordCtrl.text.trim().isEmpty
              ? null
              : _passwordCtrl.text.trim(),
          role: UserRoles.deliveryPerson,
          status: widget.user!.status,
        );
      }

      if (!mounted) return;
      // Pop with the saved UserModel — parent updates list instantly
      Navigator.of(context, rootNavigator: true).pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saveError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _saveError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFFBF8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kOrangeLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEdit
                  ? Icons.edit_rounded
                  : Icons.person_add_rounded,
              color: _kOrange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEdit
                  ? 'Edit Delivery Partner'
                  : 'Add Delivery Partner',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Avatar upload ─────────────────────────────────────
              _AvatarSection(
                bytes: _avatarBytes,
                existingUrl: widget.user?.avatarUrl ?? '',
                uploading: _uploading,
                uploadError: _uploadError,
                onPick: _pickAvatar,
              ),

              const SizedBox(height: 16),

              // ── Name ──────────────────────────────────────────────
              _DialogField(
                controller: _nameCtrl,
                label: 'Full name *',
                icon: Icons.person_rounded,
              ),

              // ── Phone ─────────────────────────────────────────────
              _DialogField(
                controller: _phoneCtrl,
                label: 'Phone number *',
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
              ),

              // ── Email ─────────────────────────────────────────────
              _DialogField(
                controller: _emailCtrl,
                label: 'Email (optional)',
                icon: Icons.email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              // ── Password ─────────────────────────────────────────────
              _DialogField(
                controller: _passwordCtrl,
                label: _isEdit
                    ? 'Password (leave blank to keep current)'
                    : 'Password *',
                icon: Icons.lock_rounded,
                obscureText: true,
              ),

              // ── Save error ────────────────────────────────────────
              if (_saveError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _saveError!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _saving ? null : () => Navigator.pop(context, null),
          child: const Text('Cancel',
              style: TextStyle(color: _kTextMid)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _kOrange,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 12),
          ),
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(
                  _isEdit
                      ? Icons.save_rounded
                      : Icons.person_add_rounded,
                  size: 18,
                ),
          label: Text(
            _saving
                ? 'Saving…'
                : (_isEdit ? 'Save changes' : 'Add partner'),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

// ─── Avatar Section ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.bytes,
    required this.existingUrl,
    required this.uploading,
    required this.uploadError,
    required this.onPick,
  });

  final Uint8List? bytes;
  final String existingUrl;
  final bool uploading;
  final String? uploadError;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final hasExisting = existingUrl.startsWith('http');

    return GestureDetector(
      onTap: uploading ? null : onPick,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile photo (optional)',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _kTextDark),
          ),
          const SizedBox(height: 8),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder),
            ),
            child: uploading
                ? const Center(
                    child: CircularProgressIndicator(color: _kOrange))
                : bytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.memory(bytes!, fit: BoxFit.cover,
                            gaplessPlayback: true),
                      )
                    : hasExisting
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            child: Image.network(existingUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const _AvatarPlaceholder()),
                          )
                        : const _AvatarPlaceholder(),
          ),
          if (uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(uploadError!,
                  style: const TextStyle(
                      color: Color(0xFFDC2626), fontSize: 12)),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                bytes != null || hasExisting
                    ? '✅ Photo ready — tap to change'
                    : 'Tap to upload a photo',
                style: TextStyle(
                  fontSize: 12,
                  color: bytes != null || hasExisting
                      ? const Color(0xFF16A34A)
                      : _kTextMid,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_upload_outlined,
              size: 32, color: _kOrange),
          SizedBox(height: 6),
          Text('Tap to upload',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: _kTextMid,
                  fontSize: 13)),
          Text('PNG or JPG',
              style: TextStyle(fontSize: 11, color: _kTextMid)),
        ],
      ),
    );
  }
}

// ─── Dialog Field ─────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: _kTextMid),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: _kOrange, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ─── Admin Drawer ─────────────────────────────────────────────────────────────

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer(
      {required this.onNavigate, required this.onLogout});
  final void Function(String) onNavigate;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin =
        context.read<AppState>().user?.role == UserRoles.superAdmin;

    final items = [
      ('Overview', Icons.dashboard_rounded,
          AdminDashboardScreen.routeName),
      ('Orders', Icons.receipt_long_rounded,
          AdminOrdersScreen.routeName),
      ('Notifications', Icons.notifications_active_rounded,
          AdminNotificationsScreen.routeName),
      ('Products', Icons.inventory_2_rounded,
          ManageProductsScreen.routeName),
      ('Categories', Icons.category_rounded,
          ManageCategoriesScreen.routeName),
      ('Banners', Icons.slideshow_rounded,
          ManageBannersScreen.routeName),
      if (isSuperAdmin)
        ('Users', Icons.groups_rounded, ManageUsersScreen.routeName),
      ('Delivery partners', Icons.delivery_dining_rounded,
          ManageDeliveryScreen.routeName),
      ('Stock alerts', Icons.warning_amber_rounded,
          StockScreen.routeName),
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
                    backgroundColor: _kOrangeLight,
                    child: Icon(Icons.admin_panel_settings_rounded,
                        color: _kOrange),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin menu',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: _kTextDark)),
                        SizedBox(height: 2),
                        Text('Navigate the control centre',
                            style: TextStyle(
                                color: _kTextMid, fontSize: 12)),
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
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final item = items[i];
                  final sel =
                      item.$3 == ManageDeliveryScreen.routeName;
                  return Material(
                    color:
                        sel ? _kOrangeLight : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onNavigate(item.$3),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _kOrange.withValues(
                                    alpha: sel ? 0.18 : 0.08),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Icon(item.$2,
                                  color: sel
                                      ? _kOrange
                                      : const Color(0xFF555555),
                                  size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: sel
                                        ? _kOrange
                                        : _kTextDark,
                                  )),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                color: sel
                                    ? _kOrange
                                    : const Color(0xFFCCCCCC),
                                size: 18),
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
                  onPressed: onLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kOrange,
                    side: const BorderSide(color: _kOrange),
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _kOrangeLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout',
                      style:
                          TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _DeliveryPartnerRow {
  const _DeliveryPartnerRow({
    required this.user,
    required this.isOnline,
  });

  final UserModel user;
  final bool isOnline;
}

bool _isOnlineFromBackend({
  required UserModel user,
  Map<String, dynamic>? deliveryDoc,
}) {
  final isOnline = deliveryDoc?['isOnline'];
  if (isOnline is bool) return isOnline;
  final deliveryUser = deliveryDoc?['user'];
  if (deliveryUser is Map<String, dynamic>) {
    final deliveryStatus = (deliveryUser['status'] ?? '').toString().toLowerCase();
    if (deliveryStatus == 'online') return true;
    if (deliveryStatus == 'offline') return false;
  }
  return false;
}

String _statusLabel(UserModel user, {required bool isOnline}) {
  return isOnline ? 'Online' : 'Offline';
}

String _vehicleFor(UserModel user) {
  final n = user.name.toLowerCase();
  if (n.contains('bike')) return 'Bike';
  if (n.contains('van')) return 'Van';
  if (n.contains('scooter')) return 'E-Scooter';
  return 'E-Bike';
}
