import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_sidebar_drawer.dart';

const _bg = Color(0xFFF7F8FC);
const _card = Colors.white;
const _textDark = Color(0xFF15202B);
const _textMid = Color(0xFF667085);
const _border = Color(0xFFE6E8EF);
const _accent = Color(0xFFFF6A00);
const _accentSoft = Color(0xFFFFEFE4);

class HelpSupportManagementScreen extends StatefulWidget {
  const HelpSupportManagementScreen({super.key});

  static const routeName = '/admin/help-support';

  @override
  State<HelpSupportManagementScreen> createState() => _HelpSupportManagementScreenState();
}

class _HelpSupportManagementScreenState extends State<HelpSupportManagementScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchCtrl = TextEditingController();
  final _replyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _statusFilter = 'all';
  String _priorityFilter = 'all';
  String _issueFilter = 'all';
  String _assignedFilter = 'all';
  String _selectedTab = 'all';
  final ApiService _api = ApiService();
  bool _loading = true;
  bool _savingStatus = false;
  String? _error;
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic>? _selectedTicket;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _replyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final query = <String, String>{
        if (_searchCtrl.text.trim().isNotEmpty) 'search': _searchCtrl.text.trim(),
        if (_statusFilter != 'all') 'status': _statusFilter,
        if (_issueFilter != 'all') 'issueType': _issueFilter,
        if (_priorityFilter != 'all') 'priority': _priorityFilter,
        if (_assignedFilter != 'all') 'assignedTo': _assignedFilter,
      };
      final path = '/admin/support/tickets${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}';
      final data = await _api.get(path, token: context.read<AppState>().token);
      final payload = data is Map<String, dynamic> ? data['items'] ?? data['tickets'] ?? [] : data;
      final items = (payload as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      if (!mounted) return;
      setState(() => _tickets = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTickets {
    return _tickets.where((ticket) {
      final q = _searchCtrl.text.trim().toLowerCase();
      final user = ticket['user'] is Map ? Map<String, dynamic>.from(ticket['user'] as Map) : null;
      final matchesSearch = q.isEmpty ||
          '${ticket['ticketNumber']} ${user?['name'] ?? ticket['userName'] ?? ''} ${user?['phone'] ?? ticket['phone'] ?? ''} ${ticket['orderId'] ?? ''} ${ticket['subject'] ?? ''}'
              .toLowerCase()
              .contains(q);
      final matchesStatus = _statusFilter == 'all' || ticket['status'] == _statusFilter;
      final matchesPriority = _priorityFilter == 'all' || ticket['priority'] == _priorityFilter;
      final matchesIssue = _issueFilter == 'all' || ticket['issueType'] == _issueFilter;
      final matchesAssigned = _assignedFilter == 'all' || ticket['assignedTo'] == _assignedFilter;
      final matchesTab = _selectedTab == 'all' || ticket['status'] == _selectedTab;
      return matchesSearch && matchesStatus && matchesPriority && matchesIssue && matchesAssigned && matchesTab;
    }).toList();
  }

  Map<String, int> get _stats {
    return {
      'total': _tickets.length,
      'open': _tickets.where((t) => t['status'] == 'open').length,
      'progress': _tickets.where((t) => t['status'] == 'in_progress').length,
      'resolved': _tickets.where((t) => t['status'] == 'resolved').length,
      'closed': _tickets.where((t) => t['status'] == 'closed').length,
      'urgent': _tickets.where((t) => t['priority'] == 'urgent').length,
    };
  }

  String _fmtDate(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$day/$month/$year, $hour:$minute $period';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'in_progress':
        return const Color(0xFF2563EB);
      case 'resolved':
        return const Color(0xFF16A34A);
      case 'closed':
        return const Color(0xFF6B7280);
      default:
        return _accent;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFCA8A04);
      default:
        return const Color(0xFF16A34A);
    }
  }

  void _openTicket(Map<String, dynamic> ticket) {
    setState(() => _selectedTicket = ticket);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TicketDetailsSheet(
        ticket: ticket,
        replyCtrl: _replyCtrl,
        noteCtrl: _noteCtrl,
        currentStatus: (ticket['status'] ?? 'open').toString(),
        onReply: () async {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reply sent successfully')),
          );
        },
        onStatusChanged: (status) async {
          await _updateStatus(ticket, status);
        },
      ),
    );
  }

  Future<void> _updateStatus(Map<String, dynamic> ticket, String status) async {
    if (_savingStatus) return;
    setState(() => _savingStatus = true);
    try {
      final updated = await _api.patch(
        '/admin/support/tickets/${ticket['_id'] ?? ticket['id']}/status',
        token: context.read<AppState>().token,
        body: {
          'status': status,
          'assignedTo': ticket['assignedTo'] ?? '',
        },
      );
      if (updated is Map<String, dynamic> && updated['ticket'] is Map) {
        final updatedTicket = Map<String, dynamic>.from(updated['ticket'] as Map);
        if (!mounted) return;
        setState(() {
          final key = ticket['_id'] ?? ticket['id'];
          final index = _tickets.indexWhere((e) => (e['_id'] ?? e['id']) == key);
          if (index != -1) _tickets[index] = updatedTicket;
        });
      } else {
        await _loadTickets();
      }
    } finally {
      if (mounted) setState(() => _savingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = context.read<AppState>().user?.role == UserRoles.superAdmin;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: AdminSidebarDrawer(
        currentRoute: HelpSupportManagementScreen.routeName,
        onLogout: () async {
          await context.read<AppState>().logout();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, AdminDashboardScreen.routeName, (route) => false);
        },
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _AdminTopBar(
                title: 'Help & Support Management',
                subtitle: 'Manage, reply, assign and resolve user tickets',
                onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onRefresh: () => setState(() {}),
                currentRoleLabel: isSuperAdmin ? 'Super Admin' : 'Admin',
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.25,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StatCard(title: 'Total Tickets', value: _stats['total'].toString(), icon: Icons.receipt_long_rounded),
                  _StatCard(title: 'Open Tickets', value: _stats['open'].toString(), icon: Icons.mark_email_unread_rounded),
                  _StatCard(title: 'In Progress', value: _stats['progress'].toString(), icon: Icons.timelapse_rounded),
                  _StatCard(title: 'Resolved Tickets', value: _stats['resolved'].toString(), icon: Icons.verified_rounded),
                  _StatCard(title: 'Closed Tickets', value: _stats['closed'].toString(), icon: Icons.lock_rounded),
                  _StatCard(title: 'Avg Resolution', value: '4.2h', icon: Icons.query_stats_rounded),
                ],
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TabChip(label: 'All Tickets', selected: _selectedTab == 'all', onTap: () => setState(() => _selectedTab = 'all')),
                    _TabChip(label: 'Open', selected: _selectedTab == 'open', onTap: () => setState(() => _selectedTab = 'open')),
                    _TabChip(label: 'In Progress', selected: _selectedTab == 'in_progress', onTap: () => setState(() => _selectedTab = 'in_progress')),
                    _TabChip(label: 'Resolved', selected: _selectedTab == 'resolved', onTap: () => setState(() => _selectedTab = 'resolved')),
                    _TabChip(label: 'Closed', selected: _selectedTab == 'closed', onTap: () => setState(() => _selectedTab = 'closed')),
                    _TabChip(label: 'Urgent', selected: _selectedTab == 'urgent', onTap: () => setState(() => _selectedTab = 'urgent')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _AdminFilters(
                searchCtrl: _searchCtrl,
                statusFilter: _statusFilter,
                priorityFilter: _priorityFilter,
                issueFilter: _issueFilter,
                assignedFilter: _assignedFilter,
                onChanged: () => setState(() {}),
                onStatusChanged: (v) => setState(() => _statusFilter = v),
                onPriorityChanged: (v) => setState(() => _priorityFilter = v),
                onIssueChanged: (v) => setState(() => _issueFilter = v),
                onAssignedChanged: (v) => setState(() => _assignedFilter = v),
                onRefresh: _loadTickets,
              ),
              const SizedBox(height: 16),
              _AnalyticsSection(stats: _stats),
              const SizedBox(height: 16),
              _ActivityTimeline(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ticket Table', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textDark)),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(child: CircularProgressIndicator(color: _accent)),
                      )
                    else if (_filteredTickets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text('No support tickets found.')),
                      )
                    else
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: const MaterialStatePropertyAll(Color(0xFFF6F7FA)),
                          columns: const [
                            DataColumn(label: Text('Ticket ID')),
                            DataColumn(label: Text('User Name')),
                            DataColumn(label: Text('User Phone')),
                            DataColumn(label: Text('Order ID')),
                            DataColumn(label: Text('Issue Type')),
                            DataColumn(label: Text('Subject')),
                            DataColumn(label: Text('Priority')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Created Date')),
                            DataColumn(label: Text('Assigned To')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: _filteredTickets.map((ticket) {
                            final user = ticket['user'] is Map ? Map<String, dynamic>.from(ticket['user'] as Map) : null;
                            return DataRow(
                              cells: [
                                DataCell(Text(ticket['ticketNumber'] ?? ticket['id'] ?? '')),
                                DataCell(Text(user?['name']?.toString() ?? ticket['userName']?.toString() ?? '')),
                                DataCell(Text(user?['phone']?.toString() ?? ticket['phone']?.toString() ?? '')),
                                DataCell(Text(ticket['orderId']?.toString() ?? '')),
                                DataCell(Text(ticket['issueType']?.toString() ?? '')),
                                DataCell(Text(ticket['subject']?.toString() ?? '')),
                                DataCell(_LabelBadge(text: ticket['priority']?.toString() ?? 'low', color: _priorityColor(ticket['priority']?.toString() ?? 'low'))),
                                DataCell(_LabelBadge(text: ticket['status']?.toString() ?? 'open', color: _statusColor(ticket['status']?.toString() ?? 'open'))),
                                DataCell(Text(_fmtDate(DateTime.tryParse(ticket['createdAt']?.toString() ?? '') ?? DateTime.now()))),
                                DataCell(Text(ticket['assignedTo']?.toString() ?? '')),
                                DataCell(
                                  Row(
                                    children: [
                                      IconButton(
                                        tooltip: 'View',
                                        onPressed: () => _openTicket(ticket),
                                        icon: const Icon(Icons.visibility_rounded),
                                      ),
                                      IconButton(
                                        tooltip: 'Reply',
                                        onPressed: () => _openTicket(ticket),
                                        icon: const Icon(Icons.reply_rounded),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminTopBar extends StatelessWidget {
  const _AdminTopBar({
    required this.title,
    required this.subtitle,
    required this.onOpenMenu,
    required this.onRefresh,
    required this.currentRoleLabel,
  });

  final String title;
  final String subtitle;
  final VoidCallback onOpenMenu;
  final VoidCallback onRefresh;
  final String currentRoleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _TopActionButton(icon: Icons.menu_rounded, onTap: onOpenMenu),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: _textMid)),
              ],
            ),
          ),
          _RolePill(label: currentRoleLabel),
          const SizedBox(width: 10),
          _TopActionButton(icon: Icons.refresh_rounded, onTap: onRefresh),
        ],
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _accentSoft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: _accent),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _accentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _accent)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.icon});
  final String title;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.help_outline_rounded, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(color: _textMid, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _textDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        label: Text(label),
        labelStyle: TextStyle(
          color: selected ? Colors.white : _textDark,
          fontWeight: FontWeight.w800,
        ),
        selectedColor: _accent,
        backgroundColor: _card,
        shape: StadiumBorder(side: BorderSide(color: selected ? _accent : _border)),
      ),
    );
  }
}

class _AdminFilters extends StatelessWidget {
  const _AdminFilters({
    required this.searchCtrl,
    required this.statusFilter,
    required this.priorityFilter,
    required this.issueFilter,
    required this.assignedFilter,
    required this.onChanged,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onIssueChanged,
    required this.onAssignedChanged,
    required this.onRefresh,
  });

  final TextEditingController searchCtrl;
  final String statusFilter;
  final String priorityFilter;
  final String issueFilter;
  final String assignedFilter;
  final VoidCallback onChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onPriorityChanged;
  final ValueChanged<String> onIssueChanged;
  final ValueChanged<String> onAssignedChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          TextField(
            controller: searchCtrl,
            onChanged: (_) => onChanged(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: 'Search by ticket ID, user name, phone, or order ID',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: const Color(0xFFF9FAFC),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _filterDropdown('Status', statusFilter, ['all', 'open', 'in_progress', 'resolved', 'closed'], onStatusChanged),
              _filterDropdown('Priority', priorityFilter, ['all', 'low', 'medium', 'high', 'urgent'], onPriorityChanged),
              _filterDropdown('Issue Type', issueFilter, ['all', 'order_issue', 'payment_issue', 'delivery_issue', 'missing_item', 'wrong_item', 'damaged_product', 'refund_request', 'app_bug', 'account_issue', 'other'], onIssueChanged),
              _filterDropdown('Assigned', assignedFilter, ['all', 'Admin A', 'Admin B'], onAssignedChanged),
              SizedBox(
                width: 220,
                child: OutlinedButton.icon(
                  onPressed: () => onRefresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, String value, List<String> items, ValueChanged<String> onChanged) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e == 'all' ? 'All $label' : e))).toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: const Color(0xFFF9FAFC),
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  const _AnalyticsSection({required this.stats});
  final Map<String, int> stats;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analytics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textDark)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MiniMetric(label: 'By Status', value: '${stats['open']} open, ${stats['progress']} progress'),
              _MiniMetric(label: 'By Priority', value: '${stats['urgent']} urgent tickets'),
              _MiniMetric(label: 'Daily Volume', value: '${stats['total']} total today'),
              _MiniMetric(label: 'Performance', value: '4.2h avg resolution'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: _textMid)),
        ],
      ),
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Ticket created', 'Order delayed beyond ETA', Icons.add_circle_outline_rounded),
      ('Admin replied', 'User informed about next update', Icons.reply_rounded),
      ('Status changed', 'Moved to In Progress', Icons.swap_horiz_rounded),
      ('Ticket resolved', 'Issue closed successfully', Icons.verified_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textDark)),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.$3, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text(item.$2, style: const TextStyle(color: _textMid, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabelBadge extends StatelessWidget {
  const _LabelBadge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}

class _TicketDetailsSheet extends StatelessWidget {
  const _TicketDetailsSheet({
    required this.ticket,
    required this.replyCtrl,
    required this.noteCtrl,
    required this.currentStatus,
    required this.onReply,
    required this.onStatusChanged,
  });

  final Map<String, dynamic> ticket;
  final TextEditingController replyCtrl;
  final TextEditingController noteCtrl;
  final String currentStatus;
  final VoidCallback onReply;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final user = ticket['user'] is Map ? Map<String, dynamic>.from(ticket['user'] as Map) : null;
    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                (ticket['ticketNumber'] ?? ticket['id'] ?? '').toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text((ticket['subject'] ?? '').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _detailRow('User', user?['name'] ?? ticket['userName'] ?? ''),
              _detailRow('Phone', user?['phone'] ?? ticket['phone'] ?? ''),
              _detailRow('Email', user?['email'] ?? ticket['email'] ?? ''),
              _detailRow('Order ID', ticket['orderId'] ?? ''),
              _detailRow('Issue Type', ticket['issueType'] ?? ''),
              _detailRow('Priority', ticket['priority'] ?? ''),
              _detailRow('Status', ticket['status'] ?? ''),
              _detailRow('Assigned To', ticket['assignedTo'] ?? ''),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: currentStatus,
                items: const [
                  DropdownMenuItem(value: 'open', child: Text('Open')),
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (value) {
                  if (value != null) onStatusChanged(value);
                },
                decoration: const InputDecoration(
                  labelText: 'Update Status',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Description', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text((ticket['description'] ?? '').toString()),
              const SizedBox(height: 16),
              TextField(
                controller: replyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Reply to user',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Internal note',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReply,
                      child: const Text('Save as Internal Note'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _accent),
                      onPressed: onReply,
                      child: const Text('Send Reply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(child: Text((value ?? '').toString())),
        ],
      ),
    );
  }
}
