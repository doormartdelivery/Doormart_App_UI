import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../models/vendor_model.dart';
import '../../providers/app_state.dart';
import '../../features/operations/services/location_service.dart';
import '../admin/admin_sidebar_drawer.dart';

const _bg = Color(0xFFF6F7FB);
const _card = Colors.white;
const _textDark = Color(0xFF111827);
const _textMid = Color(0xFF6B7280);
const _border = Color(0xFFE5E7EB);
const _accent = Color(0xFFE8541A);
const _accentSoft = Color(0xFFFFF0EB);
const _violet = Color(0xFF7C3AED);
const _ink = Color(0xFF0F172A);

class VendorProfileScreen extends StatelessWidget {
  const VendorProfileScreen({super.key});

  static const routeName = '/vendor/profile';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final user = state.user;
        final vendor = state.vendor ?? _vendorFromUser(user) ?? _emptyVendor();
        final displayId = _formatVendorDisplayId(vendor.vendorId, vendor.id);
        final approvalStatus = vendor.approvalStatus.toLowerCase();
        final isApproved = approvalStatus == 'approved';
        final orders = state.adminOrders
            .where((order) => _matchesVendor(order.vendorId, vendor))
            .toList();
        final products = state.products
            .where((product) => _matchesVendor(product.vendorId, vendor))
            .toList();
        final activeProducts = products.where((p) => p.stock > 0).length;
        final totalSales = orders.fold<double>(
          0,
          (sum, order) => sum + order.total,
        );

        return Scaffold(
          backgroundColor: _bg,
          drawer: AdminSidebarDrawer(
            currentRoute: VendorProfileScreen.routeName,
            onLogout: () async {
              final logoutRoute = context.read<AppState>().logoutRouteName;
              await context.read<AppState>().logout();
              if (!context.mounted) return;
              Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamedAndRemoveUntil(logoutRoute, (route) => false);
            },
          ),
          body: SafeArea(
            child: RefreshIndicator(
              color: _accent,
              onRefresh: () async {
                await context.read<AppState>().refreshProfile();
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  Row(
                    children: [
                      Builder(
                        builder: (menuContext) => IconButton.filledTonal(
                          onPressed: () =>
                              Scaffold.of(menuContext).openDrawer(),
                          style: IconButton.styleFrom(
                            backgroundColor: _card,
                            foregroundColor: _textDark,
                          ),
                          icon: const Icon(Icons.menu_rounded),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ProfileHero(
                    vendor: vendor,
                    user: user,
                    displayId: displayId,
                    approvalStatus: approvalStatus,
                    isApproved: isApproved,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Orders',
                          value: orders.length.toString(),
                          icon: Icons.receipt_long,
                          accent: const Color(0xFF0F766E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Products',
                          value: products.length.toString(),
                          icon: Icons.inventory_2_outlined,
                          accent: _violet,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Active Products',
                          value: activeProducts.toString(),
                          icon: Icons.storefront_outlined,
                          accent: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Sales',
                          value: 'Rs ${totalSales.toStringAsFixed(0)}',
                          icon: Icons.payments_outlined,
                          accent: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Account Details',
                    children: [
                      _DetailRow(label: 'Vendor ID', value: displayId),
                      _DetailRow(
                        label: 'Owner Name',
                        value: vendor.ownerName.isNotEmpty
                            ? vendor.ownerName
                            : (user?.name ?? '-'),
                      ),
                      _DetailRow(
                        label: 'Mobile Number',
                        value: vendor.phone.isNotEmpty
                            ? vendor.phone
                            : (user?.phone ?? '-'),
                      ),
                      _DetailRow(
                        label: 'Email',
                        value: (vendor.email ?? '').isNotEmpty
                            ? vendor.email!
                            : (user?.email ?? '-'),
                      ),
                      _DetailRow(
                        label: 'Approval Status',
                        value: _titleCase(approvalStatus),
                        valueColor: _statusColor(approvalStatus),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Business Profile',
                    children: [
                      _DetailRow(
                        label: 'Store Name',
                        value: vendor.name.isNotEmpty ? vendor.name : '-',
                      ),
                      _DetailRow(
                        label: 'Business Type',
                        value: vendor.businessType.isNotEmpty
                            ? vendor.businessType
                            : '-',
                      ),
                      _DetailRow(
                        label: 'GST Number',
                        value: vendor.gstin.isNotEmpty ? vendor.gstin : '-',
                      ),
                      _DetailRow(
                        label: 'PAN Number',
                        value: vendor.panNumber.isNotEmpty
                            ? vendor.panNumber
                            : '-',
                      ),
                      _DetailRow(
                        label: 'Store Address',
                        value: vendor.address.isNotEmpty ? vendor.address : '-',
                      ),
                      _DetailRow(
                        label: 'Pickup Address',
                        value: vendor.pickupAddress.isNotEmpty
                            ? vendor.pickupAddress
                            : '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Pickup Address',
                    subtitle:
                        'Keep the pickup location updated so orders and delivery routing stay accurate.',
                    children: [
                      Text(
                        vendor.pickupAddress.isNotEmpty ||
                                vendor.city.isNotEmpty ||
                                vendor.state.isNotEmpty ||
                                vendor.pincode.isNotEmpty
                            ? _pickupSummary(vendor)
                            : 'No pickup address has been added yet.',
                        style: const TextStyle(
                          height: 1.4,
                          color: _textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (vendor.pickupLatitude != null &&
                          vendor.pickupLongitude != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Coordinates: ${vendor.pickupLatitude!.toStringAsFixed(6)}, ${vendor.pickupLongitude!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: _textMid,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _accent,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () =>
                              _showPickupAddressEditor(context, vendor),
                          icon: const Icon(Icons.edit_location_alt_outlined),
                          label: const Text(
                            'Edit Pickup Address',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Documents',
                    subtitle: 'Uploaded files for verification and records',
                    children: [
                      _DocumentCard(
                        title: 'Store Logo',
                        url: vendor.logoUrl,
                        fallbackLabel: vendor.name.isNotEmpty
                            ? vendor.name
                            : 'Logo',
                      ),
                      _DocumentCard(
                        title: 'GST Certificate',
                        url: vendor.gstCertificateUrl,
                        fallbackLabel: 'GST Certificate',
                      ),
                      _DocumentCard(
                        title: 'PAN Card',
                        url: vendor.panCardUrl,
                        fallbackLabel: 'PAN Card',
                      ),
                      _DocumentCard(
                        title: 'Cancelled Cheque',
                        url: vendor.cancelledChequeUrl,
                        fallbackLabel: 'Cancelled Cheque',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'Quick Actions',
                    children: [
                      _ActionButton(
                        icon: Icons.copy_rounded,
                        label: 'Copy Vendor ID',
                        onTap: () async {
                          await Clipboard.setData(
                            ClipboardData(text: displayId),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vendor ID copied')),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.refresh_rounded,
                        label: 'Refresh Profile',
                        onTap: () async {
                          await context.read<AppState>().refreshProfile();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile refreshed')),
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.support_agent_rounded,
                        label: 'Contact Support',
                        onTap: () async {
                          final uri = Uri.parse(
                            'mailto:doormartdelivery@gmail.com?subject=Vendor%20Support',
                          );
                          await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                      _ActionButton(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        danger: true,
                        onTap: () async {
                          final logoutRoute = context
                              .read<AppState>()
                              .logoutRouteName;
                          await context.read<AppState>().logout();
                          if (!context.mounted) return;
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushNamedAndRemoveUntil(
                            logoutRoute,
                            (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.vendor,
    required this.user,
    required this.displayId,
    required this.approvalStatus,
    required this.isApproved,
  });

  final VendorModel vendor;
  final UserModel? user;
  final String displayId;
  final String approvalStatus;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final title = vendor.name.isNotEmpty
        ? vendor.name
        : (user?.name ?? 'Vendor Profile');
    final subtitle = vendor.ownerName.trim().isNotEmpty
        ? vendor.ownerName
        : (user?.name ?? 'Business account');
    final badgeColor = _statusColor(approvalStatus);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFFE8541A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _GlowCircle(color: Colors.white.withValues(alpha: 0.09)),
          ),
          Positioned(
            left: -32,
            bottom: -36,
            child: _GlowCircle(
              color: const Color(0xFFFFC9B4).withValues(alpha: 0.15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileAvatar(imageUrl: vendor.logoUrl, title: title),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vendor Profile',
                            style: TextStyle(
                              color: Color(0xFFFFE8D9),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _HeroChip(icon: Icons.badge_outlined, label: displayId),
                    _HeroChip(
                      icon: isApproved
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded,
                      label: _titleCase(approvalStatus),
                      background: badgeColor.withValues(alpha: 0.18),
                      foreground: Colors.white,
                    ),
                    _HeroChip(
                      icon: Icons.business_center_outlined,
                      label: vendor.businessType.isNotEmpty
                          ? vendor.businessType
                          : 'Business Account',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.imageUrl, required this.title});

  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final initials = title.trim().isEmpty
        ? 'V'
        : title
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.isEmpty ? '' : part[0].toUpperCase())
              .join();

    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: (imageUrl ?? '').trim().isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(initials),
              )
            : _fallback(initials),
      ),
    );
  }

  Widget _fallback(String initials) {
    return Container(
      color: const Color(0xFFFFE6DA),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: _accent,
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    this.background = const Color(0xFFFFF1E8),
    this.foreground = _ink,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _textMid,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _textDark,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: _textMid, height: 1.3),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

String _pickupSummary(VendorModel vendor) {
  final parts = <String>[
    vendor.pickupAddress.trim(),
    vendor.city.trim(),
    vendor.state.trim(),
    vendor.pincode.trim(),
  ].where((part) => part.isNotEmpty).toList();
  return parts.join(', ');
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: _textMid,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? _textDark,
                fontWeight: FontWeight.w800,
                height: 1.35,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.title,
    required this.url,
    required this.fallbackLabel,
  });

  final String title;
  final String? url;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    final link = (url ?? '').trim();
    final hasImage = link.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: _accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _textDark,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasImage ? 'Uploaded and available' : fallbackLabel,
                          style: const TextStyle(color: _textMid, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    link,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _EmptyPreview(label: fallbackLabel),
                  ),
                ),
              )
            else
              _EmptyPreview(label: fallbackLabel),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFFFFFBF8),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(color: _textMid, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final Future<void> Function() onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFDC2626) : _accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            await onTap();
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            foregroundColor: color,
            backgroundColor: danger
                ? const Color(0xFFFFF1F2)
                : const Color(0xFFFFFBF8),
            side: BorderSide(color: color.withValues(alpha: 0.2)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
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

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'approved':
      return const Color(0xFF16A34A);
    case 'rejected':
      return const Color(0xFFDC2626);
    case 'suspended':
      return const Color(0xFFB45309);
    default:
      return _accent;
  }
}

String _titleCase(String value) {
  final cleaned = value.replaceAll('_', ' ').trim();
  if (cleaned.isEmpty) return '-';
  return cleaned
      .split(RegExp(r'\s+'))
      .map((part) {
        if (part.isEmpty) return part;
        return part[0].toUpperCase() + part.substring(1).toLowerCase();
      })
      .join(' ');
}

VendorModel? _vendorFromUser(UserModel? user) {
  if (user == null) return null;
  return VendorModel(
    id: user.id,
    name: user.name,
    vendorId: user.vendorId,
    ownerName: user.name,
    phone: user.phone,
    email: user.email,
    approvalStatus: user.approvalStatus,
    isActive: user.isActive,
    rejectionReason: user.rejectionReason,
    approvedBy: user.approvedBy,
    approvedAt: user.approvedAt,
  );
}

VendorModel _emptyVendor() {
  return const VendorModel(id: '', name: '', vendorId: 'main');
}

bool _matchesVendor(String? value, VendorModel? vendor) {
  final vendorId = (vendor?.vendorId ?? '').trim();
  if (vendorId.isEmpty) return false;
  return (value ?? '').trim() == vendorId;
}

Future<void> _showPickupAddressEditor(
  BuildContext context,
  VendorModel vendor,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PickupAddressEditorSheet(
      vendor: vendor,
      messenger: ScaffoldMessenger.of(context),
    ),
  );
}

class _PickupAddressEditorSheet extends StatefulWidget {
  const _PickupAddressEditorSheet({
    required this.vendor,
    required this.messenger,
  });

  final VendorModel vendor;
  final ScaffoldMessengerState messenger;

  @override
  State<_PickupAddressEditorSheet> createState() =>
      _PickupAddressEditorSheetState();
}

class _PickupAddressEditorSheetState extends State<_PickupAddressEditorSheet> {
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  double? _pickupLatitude;
  double? _pickupLongitude;
  bool _saving = false;
  bool _capturingLocation = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: widget.vendor.pickupAddress,
    );
    _cityController = TextEditingController(text: widget.vendor.city);
    _stateController = TextEditingController(text: widget.vendor.state);
    _pincodeController = TextEditingController(text: widget.vendor.pincode);
    _latController = TextEditingController(
      text: widget.vendor.pickupLatitude?.toStringAsFixed(6) ?? '',
    );
    _lngController = TextEditingController(
      text: widget.vendor.pickupLongitude?.toStringAsFixed(6) ?? '',
    );
    _pickupLatitude = widget.vendor.pickupLatitude;
    _pickupLongitude = widget.vendor.pickupLongitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    widget.messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  void _syncCoordinatesFromText() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat != null && lng != null) {
      _pickupLatitude = lat;
      _pickupLongitude = lng;
    } else {
      _pickupLatitude = null;
      _pickupLongitude = null;
    }
  }

  void _onCoordinateChanged(String _) {
    _syncCoordinatesFromText();
    setState(() {});
  }

  Future<void> _useCurrentLocation() async {
    if (_capturingLocation) return;
    setState(() => _capturingLocation = true);
    try {
      final location = await LocationService().currentLocation();
      if (!mounted) return;
      _pickupLatitude = location.latitude;
      _pickupLongitude = location.longitude;
      _latController.text = _pickupLatitude!.toStringAsFixed(6);
      _lngController.text = _pickupLongitude!.toStringAsFixed(6);
      final locationDetails = await LocationService().reverseGeocode(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return;
      if (locationDetails != null) {
        _addressController.text = locationDetails.address;
        if (locationDetails.city.isNotEmpty) {
          _cityController.text = locationDetails.city;
        }
        if (locationDetails.state.isNotEmpty) {
          _stateController.text = locationDetails.state;
        }
        if (locationDetails.pincode.isNotEmpty) {
          _pincodeController.text = locationDetails.pincode;
        }
      }
      setState(() {});
      _showMessage(
        locationDetails == null
            ? 'Current location captured. Address could not be resolved.'
            : 'Current address, city, state, and pincode filled.',
      );
    } catch (error) {
      if (!mounted) return;
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _capturingLocation = false);
      }
    }
  }

  Future<void> _save() async {
    final pickupAddress = _addressController.text.trim();
    if (pickupAddress.isEmpty) {
      _showMessage('Pickup address is required');
      return;
    }
    _syncCoordinatesFromText();
    setState(() => _saving = true);
    try {
      await context.read<AppState>().updateVendorPickupAddress(
        pickupAddress: pickupAddress,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        pincode: _pincodeController.text.trim(),
        pickupLatitude: _pickupLatitude,
        pickupLongitude: _pickupLongitude,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.messenger.showSnackBar(
        const SnackBar(content: Text('Pickup address updated')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Expanded(
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.next,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: _textMid),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: const Color(0xFFFCFCFC),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Edit Pickup Location',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill the full pickup details so the delivery partner sees '
                'the complete store location, not empty dashes.',
                style: TextStyle(color: _textMid, height: 1.35),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _addressController,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Pickup Address *',
                    hintText: 'Building, street, landmark',
                    hintStyle: const TextStyle(color: _textMid),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFCFCFC),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _field(
                    label: 'City',
                    controller: _cityController,
                    hint: 'e.g. Chennai',
                  ),
                  const SizedBox(width: 12),
                  _field(
                    label: 'State',
                    controller: _stateController,
                    hint: 'e.g. Tamil Nadu',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Pincode',
                    hintText: 'e.g. 600001',
                    hintStyle: const TextStyle(color: _textMid),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFCFCFC),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _field(
                    label: 'Latitude',
                    controller: _latController,
                    hint: 'e.g. 13.0827',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: _onCoordinateChanged,
                  ),
                  const SizedBox(width: 12),
                  _field(
                    label: 'Longitude',
                    controller: _lngController,
                    hint: 'e.g. 80.2707',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    onChanged: _onCoordinateChanged,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _capturingLocation ? null : _useCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _accent,
                    side: const BorderSide(color: Color(0xFFFFC9B4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _capturingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location_rounded),
                  label: Text(
                    _capturingLocation
                        ? 'Finding location...'
                        : 'Use Current Location',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              if (_pickupLatitude != null && _pickupLongitude != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    'Saved pin: ${_pickupLatitude!.toStringAsFixed(6)}, ${_pickupLongitude!.toStringAsFixed(6)}',
                    style: const TextStyle(
                      color: _textMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save Pickup Location',
                          style: TextStyle(fontWeight: FontWeight.w800),
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
