import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import 'admin_logout_confirm.dart';
import '../../services/api_service.dart';
import 'admin_dashboard_screen.dart';
import 'admin_orders_screen.dart';
import 'manage_banners_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_delivery_screen.dart';
import 'manage_products_screen.dart';
import 'manage_users_screen.dart';
import 'stock_screen.dart';
import 'admin_sidebar_drawer.dart';

const _bg = Color(0xFFF7F8FC);
const _card = Colors.white;
const _textDark = Color(0xFF15202B);
const _textMid = Color(0xFF667085);
const _border = Color(0xFFE6E8EF);
const _accent = Color(0xFFFF6A00);
const _accentSoft = Color(0xFFFFEFE4);

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  static const routeName = '/admin/notifications';

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  static const _prefsKeyScheduleLater = 'admin_notifications_schedule_later';
  static const _prefsKeySelectedType = 'admin_notifications_selected_type';
  static const _prefsKeySelectedAudience =
      'admin_notifications_selected_audience';
  static const _prefsKeyScheduledAt = 'admin_notifications_scheduled_at';
  static const _prefsKeyScheduleLabel = 'admin_notifications_schedule_label';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _specificUserController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final ApiService _api = ApiService();

  Timer? _refreshTimer;
  Timer? _searchDebounce;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _selectedType = 'promotion';
  String _selectedAudience = 'all_users';
  String _selectedTab = 'all';
  bool _pushEnabled = true;
  bool _logHistory = true;
  bool _scheduleLater = false;
  bool _isUploading = false;
  DateTime? _scheduledAt;
  String? _bannerUrl;
  String? _bannerName;
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_syncPreview);
    _messageController.addListener(_syncPreview);
    _loadAll();
    _restoreDraftState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadHistory(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchDebounce?.cancel();
    _titleController.dispose();
    _messageController.dispose();
    _specificUserController.dispose();
    _scheduleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _syncPreview() => setState(() {});

  Future<void> _restoreDraftState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedType = prefs.getString(_prefsKeySelectedType) ?? _selectedType;
      _selectedAudience =
          prefs.getString(_prefsKeySelectedAudience) ?? _selectedAudience;
      _scheduleLater = prefs.getBool(_prefsKeyScheduleLater) ?? _scheduleLater;
      final scheduledAtIso = prefs.getString(_prefsKeyScheduledAt);
      if (scheduledAtIso != null && scheduledAtIso.isNotEmpty) {
        final parsed = DateTime.tryParse(scheduledAtIso);
        if (parsed != null) {
          _scheduledAt = parsed.toLocal();
        }
      }
      final scheduleLabel = prefs.getString(_prefsKeyScheduleLabel);
      if (scheduleLabel != null && scheduleLabel.isNotEmpty) {
        _scheduleController.text = scheduleLabel;
      }
    });
  }

  Future<void> _persistDraftState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeySelectedType, _selectedType);
    await prefs.setString(_prefsKeySelectedAudience, _selectedAudience);
    await prefs.setBool(_prefsKeyScheduleLater, _scheduleLater);
    if (_scheduledAt != null) {
      await prefs.setString(
        _prefsKeyScheduledAt,
        _scheduledAt!.toUtc().toIso8601String(),
      );
      await prefs.setString(
        _prefsKeyScheduleLabel,
        _scheduleController.text.trim(),
      );
    } else {
      await prefs.remove(_prefsKeyScheduledAt);
      await prefs.remove(_prefsKeyScheduleLabel);
    }
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadHistory(), _loadAnalytics()]);
  }

  Future<void> _loadAnalytics() async {
    try {
      final data = await _api.get(
        '/admin/notifications/analytics',
        token: context.read<AppState>().token,
      );
      if (!mounted) return;
      setState(() => _analytics = Map<String, dynamic>.from(data as Map));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadHistory({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final query = <String, String>{
        'limit': '100',
        if (_searchController.text.trim().isNotEmpty)
          'search': _searchController.text.trim(),
        if (_selectedTab != 'all') 'status': _selectedTab,
      };
      final path =
          '/admin/notifications${query.isEmpty ? '' : '?${Uri(queryParameters: query).query}'}';
      final data = await _api.get(path, token: context.read<AppState>().token);
      final items = data is Map
          ? (data['items'] as List<dynamic>? ??
                data['notifications'] as List<dynamic>? ??
                [])
          : data is List
          ? data
          : <dynamic>[];
      if (!mounted) return;
      setState(() {
        _history = items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!silent && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String?> _uploadBannerIfNeeded() async {
    if (_bannerUrl != null && _bannerUrl!.isNotEmpty) return _bannerUrl;
    return null;
  }

  Future<void> _pickBanner() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null) return;
    setState(() {
      _isUploading = true;
      _bannerName = image.name;
    });
    try {
      final uploaded = await _api.uploadImage(
        '/categories/upload-image',
        filePath: image.path,
        fieldName: 'image',
        token: context.read<AppState>().token,
      );
      final url = (uploaded as Map<String, dynamic>)['url']?.toString();
      if (!mounted) return;
      setState(() {
        _bannerUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submit(String mode) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAudience == 'specific_user' &&
        _specificUserController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a specific user ID')),
      );
      return;
    }
    final body = <String, dynamic>{
      'title': _titleController.text.trim(),
      'message': _messageController.text.trim(),
      'type': _selectedType,
      'targetAudience': _selectedAudience,
      if (_selectedAudience == 'specific_user')
        'specificUserId': _specificUserController.text.trim(),
      'imageUrl': await _uploadBannerIfNeeded(),
    };
    if (_scheduleLater && _scheduledAt != null) {
      body['scheduledAt'] = _scheduledAt!.toUtc().toIso8601String();
    }

    try {
      setState(() => _saving = true);
      final token = context.read<AppState>().token;
      Map<String, dynamic>? sendResult;
      if (mode == 'send') {
        sendResult =
            await _api.post(
                  '/admin/notifications/send',
                  token: token,
                  body: body,
                )
                as Map<String, dynamic>;
      } else if (mode == 'draft') {
        await _api.post('/admin/notifications/draft', token: token, body: body);
      } else {
        if (_scheduledAt == null) {
          throw StateError('Please choose a schedule time');
        }
        await _api.post(
          '/admin/notifications/schedule',
          token: token,
          body: body,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            mode == 'send'
                ? sendResult == null
                      ? 'Notification sent'
                      : sendResult['totalTargets'] == 0
                      ? 'No recipients have registered notifications yet'
                      : 'Notification sent to ${sendResult['successCount'] ?? 0} of ${sendResult['totalTargets']} devices'
                : mode == 'draft'
                ? 'Draft saved'
                : 'Notification scheduled',
          ),
        ),
      );
      if (mode == 'send') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_prefsKeyScheduleLater);
        await prefs.remove(_prefsKeyScheduledAt);
        await prefs.remove(_prefsKeyScheduleLabel);
        if (!mounted) return;
        setState(() {
          _scheduleLater = false;
          _scheduledAt = null;
          _scheduleController.clear();
        });
      } else {
        await _persistDraftState();
      }
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _scheduleController.text = _formatScheduleInput(_scheduledAt!);
      _scheduleLater = true;
    });
    await _persistDraftState();
  }

  String _labelForAudience(String audience) {
    switch (audience) {
      case 'customers':
        return 'Customers';
      case 'delivery_persons':
        return 'Delivery Persons';
      case 'specific_user':
        return 'Specific User';
      default:
        return 'All Users';
    }
  }

  String _labelForType(String type) {
    switch (type) {
      case 'alert':
        return 'Alert';
      case 'update':
        return 'Update';
      case 'reminder':
        return 'Reminder';
      default:
        return 'Promotion';
    }
  }

  String _statusLabel(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString();
    if (status == 'sent') return 'Delivered';
    if (status == 'scheduled') return 'Pending';
    if (status == 'failed') return 'Failed';
    return 'Draft';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Delivered':
        return const Color(0xFF0F9D58);
      case 'Pending':
        return const Color(0xFFB7791F);
      case 'Failed':
        return const Color(0xFFDC2626);
      default:
        return _textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: AdminSidebarDrawer(
        currentRoute: AdminNotificationsScreen.routeName,
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
        child: RefreshIndicator(
          onRefresh: _loadAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 1100;
                final formWidth = wide
                    ? constraints.maxWidth * 0.58
                    : constraints.maxWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationHero(onRefresh: _loadAll),
                    const SizedBox(height: 16),
                    _AnalyticsRow(analytics: _analytics),
                    const SizedBox(height: 16),
                    wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: formWidth,
                                child: _buildComposerCard(),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: _buildPreviewColumn()),
                            ],
                          )
                        : Column(
                            children: [
                              _buildComposerCard(),
                              const SizedBox(height: 16),
                              _buildPreviewColumn(),
                            ],
                          ),
                    const SizedBox(height: 16),
                    _buildHistoryCard(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposerCard() {
    return Card(
      elevation: 0,
      color: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.campaign_outlined,
                title: 'Create Notification',
                subtitle:
                    'Compose and send push notifications to selected users.',
              ),
              const SizedBox(height: 18),
              _FieldLabel('Notification Title'),
              _InputField(
                controller: _titleController,
                hint: 'Weekend Feast 50% Off!',
              ),
              const SizedBox(height: 14),
              _FieldLabel('Message Body'),
              _InputField(
                controller: _messageController,
                hint: 'Tell your users about the amazing offer...',
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel('Notification Type'),
                        _SelectField(
                          value: _selectedType,
                          items: const [
                            DropdownMenuItem(
                              value: 'promotion',
                              child: Text('Promotion'),
                            ),
                            DropdownMenuItem(
                              value: 'alert',
                              child: Text('Alert'),
                            ),
                            DropdownMenuItem(
                              value: 'update',
                              child: Text('Update'),
                            ),
                            DropdownMenuItem(
                              value: 'reminder',
                              child: Text('Reminder'),
                            ),
                          ],
                          onChanged: (value) async {
                            setState(
                              () => _selectedType = value ?? 'promotion',
                            );
                            await _persistDraftState();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _FieldLabel('Banner Image (Optional)'),
              GestureDetector(
                onTap: _isUploading ? null : _pickBanner,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFCED6E5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: _isUploading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.file_upload_outlined,
                                color: _accent,
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _bannerUrl == null
                                  ? 'Drop image here or click to upload'
                                  : 'Uploaded successfully',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _bannerName ?? 'Recommended: 1200 x 628 px',
                              style: const TextStyle(color: _textMid),
                            ),
                          ],
                        ),
                      ),
                      if (_bannerUrl != null)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF0F9D58),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _FieldLabel('Audience Selection'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AudienceChip(
                    label: 'All Users (Customer, Vendor, Delivery)',
                    selected: _selectedAudience == 'all_users',
                    onTap: () async {
                      setState(() => _selectedAudience = 'all_users');
                      await _persistDraftState();
                    },
                  ),
                  _AudienceChip(
                    label: 'Customers',
                    selected: _selectedAudience == 'customers',
                    onTap: () async {
                      setState(() => _selectedAudience = 'customers');
                      await _persistDraftState();
                    },
                  ),
                  _AudienceChip(
                    label: 'Delivery Persons',
                    selected: _selectedAudience == 'delivery_persons',
                    onTap: () async {
                      setState(() => _selectedAudience = 'delivery_persons');
                      await _persistDraftState();
                    },
                  ),
                  _AudienceChip(
                    label: 'Specific User',
                    selected: _selectedAudience == 'specific_user',
                    onTap: () async {
                      setState(() => _selectedAudience = 'specific_user');
                      await _persistDraftState();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedAudience == 'specific_user') ...[
                _FieldLabel('Specific User ID'),
                _InputField(
                  controller: _specificUserController,
                  hint: 'Paste specific user id here',
                  validator: (value) {
                    if (_selectedAudience == 'specific_user' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'User ID is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 18),
              _FieldLabel('Delivery Settings'),
              _ToggleRow(
                label: 'Push Notification',
                value: _pushEnabled,
                onChanged: (value) => setState(() => _pushEnabled = value),
              ),
              _ToggleRow(
                label: 'Log to History',
                value: _logHistory,
                onChanged: (value) => setState(() => _logHistory = value),
              ),
              _ToggleRow(
                label: 'Schedule for later',
                value: _scheduleLater,
                onChanged: (value) async {
                  setState(() => _scheduleLater = value);
                  await _persistDraftState();
                },
              ),
              if (_scheduleLater) ...[
                const SizedBox(height: 12),
                _InputField(
                  controller: _scheduleController,
                  hint: 'Choose schedule time',
                  readOnly: true,
                  onTap: _pickSchedule,
                  suffix: IconButton(
                    onPressed: _pickSchedule,
                    icon: const Icon(Icons.schedule_rounded),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : () => _submit('send'),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send Notification Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _saving ? null : () => _submit('draft'),
                    child: const Text('Save Draft'),
                  ),
                  if (_scheduleLater)
                    OutlinedButton.icon(
                      onPressed: _saving ? null : () => _submit('schedule'),
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Save Schedule'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewColumn() {
    return Column(
      children: [
        Card(
          elevation: 0,
          color: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionTitle(
                  icon: Icons.phone_iphone,
                  title: 'Live Preview',
                  subtitle: 'See how the push card will look on mobile.',
                ),
                const SizedBox(height: 16),
                _MobilePreview(
                  title: _titleController.text.isEmpty
                      ? 'Weekend Feast 50% Off!'
                      : _titleController.text,
                  body: _messageController.text.isEmpty
                      ? 'Order your favorites now and enjoy huge savings.'
                      : _messageController.text,
                  imageUrl: _bannerUrl,
                  type: _labelForType(_selectedType),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          color: _card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  icon: Icons.lightbulb_outline,
                  title: 'Pro Tip',
                  subtitle:
                      'Notifications with images and targeted audience filters typically perform better.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryCard() {
    final filtered = _history.where((item) {
      if (_selectedTab == 'all') return true;
      return (item['status'] ?? '').toString() == _selectedTab;
    }).toList();

    return Card(
      elevation: 0,
      color: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              icon: Icons.history,
              title: 'Notification History',
              subtitle:
                  'Search, filter and inspect the latest admin notifications.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(
                  const Duration(milliseconds: 350),
                  () => _loadHistory(silent: true),
                );
              },
              decoration: InputDecoration(
                hintText: 'Search title or message',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF7F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                _TabChip(
                  label: 'All',
                  selected: _selectedTab == 'all',
                  onTap: () {
                    setState(() => _selectedTab = 'all');
                    _loadHistory();
                  },
                ),
                _TabChip(
                  label: 'Sent',
                  selected: _selectedTab == 'sent',
                  onTap: () {
                    setState(() => _selectedTab = 'sent');
                    _loadHistory();
                  },
                ),
                _TabChip(
                  label: 'Scheduled',
                  selected: _selectedTab == 'scheduled',
                  onTap: () {
                    setState(() => _selectedTab = 'scheduled');
                    _loadHistory();
                  },
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Center(child: Text('No notifications found')),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(
                    const Color(0xFFF7F9FF),
                  ),
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Audience')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Repeat')),
                    DataColumn(label: Text('Timestamp')),
                    DataColumn(label: Text('Results')),
                  ],
                  rows: filtered.map((item) {
                    final status = _statusLabel(item);
                    return DataRow(
                      cells: [
                        DataCell(Text((item['title'] ?? '').toString())),
                        DataCell(
                          Text(
                            _labelForAudience(
                              (item['targetAudience'] ?? '').toString(),
                            ),
                          ),
                        ),
                        DataCell(Text((item['type'] ?? '').toString())),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(_RepeatBadge(text: _repeatLabel(item))),
                        DataCell(Text(_formatNotificationTimestamp(item))),
                        DataCell(
                          Text(
                            '${item['successCount'] ?? 0} delivered, ${item['failureCount'] ?? 0} failed',
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 14),
            const Text(
              'Notifications with images have 35% higher CTR.',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatNotificationTimestamp(Map<String, dynamic> item) {
  final raw = item['sentAt'] ?? item['scheduledAt'] ?? item['createdAt'];
  if (raw == null) return '—';
  DateTime? dt;
  if (raw is DateTime) {
    dt = raw;
  } else {
    dt = DateTime.tryParse(raw.toString());
  }
  if (dt == null) return raw.toString();
  final local = dt.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = monthNames[local.month - 1];
  final year = local.year;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $amPm';
}

String _formatScheduleInput(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = monthNames[local.month - 1];
  final year = local.year;
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final amPm = local.hour >= 12 ? 'PM' : 'AM';
  return '$day $month $year, ${hour.toString().padLeft(2, '0')}:$minute $amPm';
}

String _repeatLabel(Map<String, dynamic> item) {
  final recurrence = (item['recurrence'] ?? 'none').toString().toLowerCase();
  final time = (item['recurrenceTime'] ?? '').toString().trim();
  if (recurrence == 'daily') {
    return time.isEmpty ? 'Daily' : 'Daily at $time';
  }
  return 'Once';
}

class _RepeatBadge extends StatelessWidget {
  const _RepeatBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDaily = text.toLowerCase().startsWith('daily');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isDaily ? const Color(0xFFEEF2FF) : const Color(0xFFF3F4F6))
            .withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDaily ? const Color(0xFF4F46E5) : _textMid,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({required this.selectedIndex, required this.onLogout});

  final int selectedIndex;
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
      child: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _accentSoft,
                      child: Icon(Icons.admin_panel_settings, color: _accent),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin menu',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _textDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Navigate the control center',
                            style: TextStyle(color: _textMid),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: _border),
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
                    final selected = index == selectedIndex;
                    return Material(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.pop(context);
                          if (item.$3 != AdminNotificationsScreen.routeName) {
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
                                  color: selected
                                      ? _accentSoft
                                      : const Color(0xFFF5F6FA),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(item.$2, color: _accent),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.$1,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _accent,
                                  ),
                                ),
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
                    onPressed: onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: const BorderSide(color: _accent),
                      backgroundColor: _accentSoft,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

class _NotificationHero extends StatelessWidget {
  const _NotificationHero({required this.onRefresh});

  final Future<void> Function() onRefresh;

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
              child: IconButton.filledTonal(
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF0EB),
                  foregroundColor: const Color(0xFFE8541A),
                ),
                icon: const Icon(Icons.refresh),
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
                    'Notification Center',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Compose, schedule, and track push notifications from one polished control panel.',
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

class _AnalyticsRow extends StatelessWidget {
  const _AnalyticsRow({required this.analytics});

  final Map<String, dynamic> analytics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Total Sent',
        (analytics['totalSent'] ?? 0).toString(),
        Icons.send_rounded,
      ),
      (
        'Delivered',
        (analytics['delivered'] ?? 0).toString(),
        Icons.done_all_rounded,
      ),
      (
        'Failed',
        (analytics['failed'] ?? 0).toString(),
        Icons.error_outline_rounded,
      ),
      (
        'Scheduled',
        (analytics['scheduled'] ?? 0).toString(),
        Icons.schedule_rounded,
      ),
    ];
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: cards
          .map(
            (card) => SizedBox(
              width: MediaQuery.of(context).size.width > 700
                  ? 220
                  : double.infinity,
              child: _StatCard(title: card.$1, value: card.$2, icon: card.$3),
            ),
          )
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: _accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: _textDark,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _accentSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: _textMid)),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, color: _textDark),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    this.controller,
    required this.hint,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.suffix,
    this.validator,
  });

  final TextEditingController? controller;
  final String hint;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final Widget? suffix;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      validator:
          validator ??
          (value) {
            if (hint.contains('Title') &&
                (value == null || value.trim().isEmpty)) {
              return 'Title is required';
            }
            if (hint.contains('Message') &&
                (value == null || value.trim().isEmpty)) {
              return 'Message is required';
            }
            return null;
          },
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SelectField extends StatelessWidget {
  const _SelectField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF7F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _AudienceChip extends StatelessWidget {
  const _AudienceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _accentSoft,
      labelStyle: TextStyle(color: _accent, fontWeight: FontWeight.w700),
      backgroundColor: _card,
      side: BorderSide(color: selected ? _accent : _border),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool? value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      value: value ?? false,
      activeColor: _accent,
      onChanged: onChanged,
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accentSoft : const Color(0xFFF7F9FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? _accent : _border),
        ),
        child: Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w800, color: _accent),
        ),
      ),
    );
  }
}

class _MobilePreview extends StatelessWidget {
  _MobilePreview({
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.type,
  });

  final String title;
  final String body;
  final String? imageUrl;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1F2937)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: AspectRatio(
        aspectRatio: 0.52,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF233043), width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(0xFFFF6A00),
                      child: Icon(
                        Icons.notifications,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DOORMART',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      type,
                      style: const TextStyle(
                        color: Color(0xFFB8C2D3),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(body, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: imageUrl == null
                            ? const [Color(0xFF1F2937), Color(0xFF0F172A)]
                            : const [Color(0xFF283041), Color(0xFF101826)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        imageUrl == null
                            ? Icons.image_outlined
                            : Icons.verified,
                        color: Colors.white70,
                        size: 42,
                      ),
                    ),
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
