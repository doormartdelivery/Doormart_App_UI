import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../../models/order_model.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../delivery/delivery_login_screen.dart';
import '../vendor/vendor_login_screen.dart';
import '../super_admin/super_admin_login_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  static const routeName = '/help';

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _supportPhone = '8248118563';
  static const _supportPhoneUri = '+918248118563';
  static const _accountDeletionSubject = 'Account deletion request';
  final _picker = ImagePicker();
  final _searchCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String _issueType = 'order_issue';
  String? _orderId;
  String? _imageUrl;
  String? _imageName;
  bool _submittingTicket = false;
  bool _uploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadSupportTickets();
      appState.loadOrders();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Could not open ${uri.toString()}');
    }
  }

  Future<void> _callSupport() => _launch(Uri.parse('tel:$_supportPhoneUri'));

  Future<void> _whatsappSupport() => _launch(
    Uri.parse(
      'https://wa.me/$_supportPhoneUri?text=${Uri.encodeComponent('Hi Doormart, I need help with my order.')}',
    ),
  );

  Future<void> _emailSupport() => _launch(
    Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': 'Doormart Support',
        'body': 'Hello Doormart support team,\n\nI need help with...',
      },
    ),
  );

  Future<void> _emailAccountDeletion() => _launch(
    Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': _accountDeletionSubject,
        'body':
            'Hello Doormart support team,\n\nI want to request deletion of my Doormart account and all associated user data.\n\nAccount email or phone:\n\nThanks.',
      },
    ),
  );

  Future<void> _submitTicket() async {
    if (_subjectCtrl.text.trim().isEmpty ||
        _descriptionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and description are required')),
      );
      return;
    }
    setState(() => _submittingTicket = true);
    try {
      await context.read<AppState>().createSupportTicket(
        subject: _subjectCtrl.text.trim(),
        issueType: _issueType,
        description: _descriptionCtrl.text.trim(),
        orderId: _orderId ?? '',
        imageUrl: _imageUrl ?? '',
      );
      _subjectCtrl.clear();
      _descriptionCtrl.clear();
      _imageUrl = null;
      _imageName = null;
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Support ticket submitted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submittingTicket = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() {
      _uploadingImage = true;
      _imageName = picked.name;
    });
    try {
      final api = context.read<AppState>().apiService;
      final token = context.read<AppState>().token;
      final dynamic uploaded = kIsWeb
          ? await api.uploadImage(
              '/support/upload-image',
              bytes: await picked.readAsBytes(),
              fileName: picked.name,
              fieldName: 'image',
              token: token,
            )
          : await api.uploadImage(
              '/support/upload-image',
              filePath: picked.path,
              fieldName: 'image',
              token: token,
            );
      if (!mounted) return;
      setState(() {
        _imageUrl = uploaded['url']?.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final state = context.watch<AppState>();
    final tickets = state.supportTickets;
    final orders = state.orders;
    final filteredTickets = tickets.where((ticket) {
      final text = '${ticket['subject'] ?? ''} ${ticket['description'] ?? ''}'
          .toLowerCase();
      return text.contains(_searchCtrl.text.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      bottomNavigationBar: BottomNavBar(
        index: 4,
        onTap: (i) => BottomNavBar.navigate(context, i),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
          children: [
            _TopBar(onBack: () => Navigator.maybePop(context)),
            const SizedBox(height: 16),
            const _HeroCard(),
            const SizedBox(height: 16),
            _SearchBar(
              controller: _searchCtrl,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Quick Help Categories'),
            const SizedBox(height: 10),
            const _CategoryGrid(),
            const SizedBox(height: 18),
            const _SectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 10),
            const _FaqSection(),
            const SizedBox(height: 18),
            const _SectionTitle('Contact Support'),
            const SizedBox(height: 10),
            _ContactCard(
              title: 'Call Customer Support',
              subtitle: 'Speak with a support agent at $_supportPhone',
              icon: Icons.call_rounded,
              onTap: _callSupport,
            ),
            _ContactCard(
              title: 'WhatsApp Support',
              subtitle: 'Quick help on WhatsApp at $_supportPhone',
              icon: Icons.chat_rounded,
              onTap: _whatsappSupport,
            ),
            _ContactCard(
              title: 'Email Support',
              subtitle: 'Send us a detailed message',
              icon: Icons.email_rounded,
              onTap: _emailSupport,
            ),
            _ContactCard(
              title: 'Delete My Account',
              subtitle:
                  'Request account deletion and removal of associated data',
              icon: Icons.delete_forever_rounded,
              onTap: _emailAccountDeletion,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('Raise a Support Ticket'),
            const SizedBox(height: 10),
            _TicketForm(
              subjectCtrl: _subjectCtrl,
              descriptionCtrl: _descriptionCtrl,
              issueType: _issueType,
              orderId: _orderId,
              orders: orders,
              imageName: _imageName,
              imageUrl: _imageUrl,
              submitting: _submittingTicket,
              uploadingImage: _uploadingImage,
              onIssueTypeChanged: (v) => setState(() => _issueType = v),
              onOrderChanged: (v) => setState(() => _orderId = v),
              onPickImage: _pickAndUploadImage,
              onSubmit: _submitTicket,
            ),
            const SizedBox(height: 18),
            const _SectionTitle('My Support Tickets'),
            const SizedBox(height: 10),
            if (filteredTickets.isEmpty)
              const _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'No support tickets yet',
                subtitle: 'Submitted tickets will appear here.',
              )
            else
              Column(
                children: filteredTickets.map((ticket) {
                  return _TicketTile(ticket: ticket);
                }).toList(),
              ),
            const _SectionTitle('Legal'),
            const SizedBox(height: 10),
            const _LegalList(),
            const SizedBox(height: 18),
            const _SectionTitle('Team Access'),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _TeamAccessTile(
                  label: 'Delivery Person',
                  subtitle: 'Partner login',
                  icon: Icons.delivery_dining_rounded,
                  accent: const Color(0xFFE8541A),
                  background: const Color(0xFFFFF6F1),
                  onTap: () => Navigator.pushNamed(
                    context,
                    DeliveryLoginScreen.routeName,
                  ),
                ),
                _TeamAccessTile(
                  label: 'Vendor Login',
                  subtitle: 'Access vendor sign in',
                  icon: Icons.storefront_rounded,
                  accent: const Color(0xFF2563EB),
                  background: const Color(0xFFF3F7FF),
                  onTap: () =>
                      Navigator.pushNamed(context, VendorLoginScreen.routeName),
                ),
                _TeamAccessTile(
                  label: 'Super Admin',
                  subtitle: 'Owner access',
                  icon: Icons.workspace_premium_rounded,
                  accent: const Color(0xFF7C3AED),
                  background: const Color(0xFFF7F3FF),
                  onTap: () => Navigator.pushNamed(
                    context,
                    SuperAdminLoginScreen.routeName,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 26),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Help & Support',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              SizedBox(height: 3),
              Text(
                "We're here to help you with your orders and account.",
                style: TextStyle(color: Color(0xFF667064), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF26522), Color(0xFFE8401A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE8541A).withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Search help, contact support, or raise a ticket in seconds.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final VoidCallback onChanged;
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'Search for help...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w900,
      color: Color(0xFF1A1A1A),
    ),
  );
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();
  @override
  Widget build(BuildContext context) {
    final categories = [
      ('Orders', Icons.receipt_long_rounded),
      ('Payments', Icons.payments_rounded),
      ('Delivery', Icons.local_shipping_rounded),
      ('Refunds', Icons.request_page_rounded),
      ('Account', Icons.person_rounded),
      ('App Issues', Icons.bug_report_rounded),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((c) {
        return Container(
          width: (MediaQuery.of(context).size.width - 42) / 2,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E8DF)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0EB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(c.$2, color: const Color(0xFFE8541A), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.$1,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _FaqSection extends StatelessWidget {
  const _FaqSection();
  @override
  Widget build(BuildContext context) {
    final faqs = <String, List<String>>{
      'Orders': [
        'How do I track my order?',
        'How can I cancel my order?',
        'Can I modify my order?',
      ],
      'Payments': [
        'Payment failed',
        'Refund status',
        'Available payment methods',
      ],
      'Delivery': [
        'Delivery delayed',
        'Delivery person not responding',
        'Missing item',
        'Wrong item delivered',
        'Damaged product',
      ],
      'Account': ['Change password', 'Update mobile number', 'Delete account'],
    };
    return Column(
      children: faqs.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3E8DF)),
          ),
          child: ExpansionTile(
            title: Text(
              entry.key,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: entry.value
                .map(
                  (q) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.fiber_manual_record,
                          size: 8,
                          color: Color(0xFFE8541A),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(q)),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFFE8541A)),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right_rounded),
        ),
      ),
    );
  }
}

class _TicketForm extends StatelessWidget {
  const _TicketForm({
    required this.subjectCtrl,
    required this.descriptionCtrl,
    required this.issueType,
    required this.orderId,
    required this.orders,
    required this.imageName,
    required this.imageUrl,
    required this.submitting,
    required this.uploadingImage,
    required this.onIssueTypeChanged,
    required this.onOrderChanged,
    required this.onPickImage,
    required this.onSubmit,
  });
  final TextEditingController subjectCtrl;
  final TextEditingController descriptionCtrl;
  final String issueType;
  final String? orderId;
  final List<OrderModel> orders;
  final String? imageName;
  final String? imageUrl;
  final bool submitting;
  final bool uploadingImage;
  final ValueChanged<String> onIssueTypeChanged;
  final ValueChanged<String?> onOrderChanged;
  final VoidCallback onPickImage;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    final issueTypes = [
      ('Order Issue', 'order_issue'),
      ('Payment Issue', 'payment_issue'),
      ('Delivery Issue', 'delivery_issue'),
      ('Product Quality', 'product_quality'),
      ('Refund Request', 'refund_request'),
      ('Technical Issue', 'technical_issue'),
      ('Other', 'other'),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: Column(
        children: [
          TextField(
            controller: subjectCtrl,
            cursorColor: const Color(0xFFE8541A),
            decoration: InputDecoration(
              labelText: 'Subject',
              labelStyle: const TextStyle(color: Color(0xFFE8541A)),
              floatingLabelStyle: const TextStyle(color: Color(0xFFE8541A)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6B39C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE8541A),
                  width: 1.8,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: const Color(0xFFFFF7F3),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: issueType,
            items: issueTypes
                .map((t) => DropdownMenuItem(value: t.$2, child: Text(t.$1)))
                .toList(),
            onChanged: (v) {
              if (v != null) onIssueTypeChanged(v);
            },
            decoration: InputDecoration(
              labelText: 'Issue Type',
              labelStyle: const TextStyle(color: Color(0xFFE8541A)),
              floatingLabelStyle: const TextStyle(color: Color(0xFFE8541A)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6B39C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE8541A),
                  width: 1.8,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: const Color(0xFFFFF7F3),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: orderId,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('No order selected'),
              ),
              ...orders.map(
                (order) => DropdownMenuItem<String?>(
                  value: order.id,
                  child: Text(order.displayOrderId),
                ),
              ),
            ],
            onChanged: onOrderChanged,
            decoration: InputDecoration(
              labelText: 'Order Selection (Optional)',
              labelStyle: const TextStyle(color: Color(0xFFE8541A)),
              floatingLabelStyle: const TextStyle(color: Color(0xFFE8541A)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6B39C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE8541A),
                  width: 1.8,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: const Color(0xFFFFF7F3),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descriptionCtrl,
            maxLines: 5,
            cursorColor: const Color(0xFFE8541A),
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: const TextStyle(color: Color(0xFFE8541A)),
              floatingLabelStyle: const TextStyle(color: Color(0xFFE8541A)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE6B39C)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE8541A),
                  width: 1.8,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              filled: true,
              fillColor: const Color(0xFFFFF7F3),
            ),
          ),
          const SizedBox(height: 12),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE3E8DF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.image_rounded, color: Color(0xFFE8541A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      imageName ?? 'Selected image',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.check_circle_rounded, color: Colors.green),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: uploadingImage ? null : onPickImage,
              icon: uploadingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(uploadingImage ? 'Uploading...' : 'Upload Image'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  return states.contains(MaterialState.hovered)
                      ? Colors.white
                      : const Color(0xFFE8541A);
                }),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  return states.contains(MaterialState.hovered)
                      ? const Color(0xFFE8541A)
                      : Colors.white;
                }),
                side: MaterialStateProperty.resolveWith((states) {
                  return const BorderSide(color: Color(0xFFE8541A), width: 1.6);
                }),
                overlayColor: MaterialStateProperty.resolveWith((states) {
                  return const Color(0xFFE8541A).withValues(alpha: 0.12);
                }),
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Text(
                      'Submit Ticket',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});
  final Map<String, dynamic> ticket;
  @override
  Widget build(BuildContext context) {
    final status = (ticket['status'] as String? ?? 'open').replaceAll('_', ' ');
    final statusColor = switch ((ticket['status'] as String? ?? 'open')
        .toLowerCase()) {
      'in_progress' => Colors.blue,
      'resolved' => Colors.green,
      'closed' => Colors.grey,
      _ => const Color(0xFFE8541A),
    };
    final latestReply = _latestCustomerReply(ticket);
    final replyMessage = latestReply?['message']?.toString().trim() ?? '';
    final replyDate = _formatTicketDate(latestReply?['createdAt']?.toString());
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket['ticketNumber']?.toString() ?? 'TKT-00000',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket['subject']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTicketDate(ticket['createdAt']?.toString()),
                  style: const TextStyle(
                    color: Color(0xFF667064),
                    fontSize: 12,
                  ),
                ),
                if (replyMessage.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F7FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFBCD2F4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.support_agent,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Support reply',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                replyDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          replyMessage,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            height: 1.35,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalList extends StatelessWidget {
  const _LegalList();
  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Privacy Policy',
        [
          'We collect only the data needed to process orders and support requests.',
          'Your data is protected and never shared without a valid business reason.',
        ],
      ),
      (
        'Terms & Conditions',
        [
          'Using the app means you agree to DoorMart service terms and order policies.',
          'Orders, refunds, and cancellations follow the app rules and local laws.',
        ],
      ),
      (
        'Refund Policy',
        [
          'Refunds are processed for eligible orders after verification.',
          'The amount is returned to the original payment method when applicable.',
        ],
      ),
      (
        'Cancellation Policy',
        [
          'Orders can be cancelled before they are packed or assigned for delivery.',
          'Some orders may not be cancellable after the preparation stage starts.',
        ],
      ),
      (
        'About DoorMart',
        [
          'DoorMart delivers groceries, daily essentials, and household items quickly.',
          'We focus on speed, freshness, and reliable customer support.',
        ],
      ),
    ];
    return Column(
      children: items
          .map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE3E8DF)),
              ),
              child: ExpansionTile(
                title: Text(
                  item.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: item.$2
                    .map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.fiber_manual_record,
                              size: 8,
                              color: Color(0xFFE8541A),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(line)),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TeamAccessTile extends StatelessWidget {
  const _TeamAccessTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: 0.28),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: const Color(0xFF1A1A1A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: accent.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamAccessButton extends StatelessWidget {
  const _TeamAccessButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE8541A),
            side: const BorderSide(color: Color(0xFFFFC9B4)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8DF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF667064)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

String _formatTicketDate(String? raw) {
  if (raw == null || raw.isEmpty) return 'Just now';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return 'Just now';
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final year = dt.year;
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final minute = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/$year, $hour:$minute $period';
}

Map<String, dynamic>? _latestCustomerReply(Map<String, dynamic> ticket) {
  final rawNotes = ticket['internalNotes'];
  if (rawNotes is! List) return null;
  final notes = rawNotes
      .whereType<Map>()
      .map((note) => Map<String, dynamic>.from(note))
      .where(
        (note) =>
            (note['visibility']?.toString().trim().toLowerCase() ??
                'customer') ==
            'customer',
      )
      .toList();
  if (notes.isEmpty) return null;
  return notes.last;
}
