import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../providers/app_state.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'login_screen.dart';
import 'address_screen.dart';
import 'help_support_screen.dart';
import 'my_orders_screen.dart';
import 'notification_screen.dart';
import 'privacy_policy_screen.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFF6F6F6);
const _kGreen = Color(0xFF0F9D58);
const _kGreenLight = Color(0xFFEAF7EF);
const _kCard = Colors.white;
const _kTextDark = Color(0xFF1A1A1A);
const _kTextMid = Color(0xFF667064);
const _kBorder = Color(0xFFE3E8DF);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  static const routeName = '/profile';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<void> _emailAccountDeletion() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': 'Account deletion request',
        'body':
            'Hello Doormart support team,\n\nI want to request deletion of my Doormart account and all associated user data.\n\nAccount email or phone:\n\nThanks.',
      },
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open email app')));
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<AppState>();
      if (state.signedIn) {
        state.loadAddresses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: _kBg,
      bottomNavigationBar: BottomNavBar(
        index: 4,
        onTap: (i) => BottomNavBar.navigate(context, i),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset),
          children: [
            // ── Hero header ─────────────────────────────────────────────
            _HeroCard(state: state),

            const SizedBox(height: 16),

            // ── Stats row ───────────────────────────────────────────────
            _StatsRow(state: state),

            const SizedBox(height: 20),

            // ── Section: Account ────────────────────────────────────────
            const _SectionLabel('Account'),
            const SizedBox(height: 10),

            _MenuTile(
              icon: Icons.receipt_long_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'My Orders',
              subtitle: 'View recent and repeat orders',
              badge: state.orders.isNotEmpty ? '${state.orders.length}' : null,
              onTap: () =>
                  Navigator.pushNamed(context, MyOrdersScreen.routeName),
            ),

            _MenuTile(
              icon: Icons.location_on_rounded,
              iconBg: const Color(0xFFECFDF5),
              iconColor: _kGreen,
              title: 'Saved Addresses',
              subtitle: 'Home, work and other locations',
              onTap: () =>
                  Navigator.pushNamed(context, AddressScreen.routeName),
            ),

            _MenuTile(
              icon: Icons.notifications_active_rounded,
              iconBg: const Color(0xFFFFFBEB),
              iconColor: const Color(0xFFD97706),
              title: 'Notifications',
              subtitle: 'Order updates and offers',
              onTap: () =>
                  Navigator.pushNamed(context, NotificationScreen.routeName),
            ),

            const SizedBox(height: 20),

            // ── Section: Preferences ─────────────────────────────────────
            const _SectionLabel('Preferences'),
            const SizedBox(height: 10),

            _MenuTile(
              icon: Icons.help_outline_rounded,
              iconBg: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF16A34A),
              title: 'Help & Support',
              subtitle: '24/7 customer care',
              onTap: () =>
                  Navigator.pushNamed(context, HelpSupportScreen.routeName),
            ),

            _MenuTile(
              icon: Icons.privacy_tip_rounded,
              iconBg: const Color(0xFFFFF7ED),
              iconColor: const Color(0xFFEA580C),
              title: 'Privacy Policy',
              subtitle: 'Terms, policy and legal info',
              onTap: () =>
                  Navigator.pushNamed(context, PrivacyPolicyScreen.routeName),
            ),

            _MenuTile(
              icon: Icons.delete_forever_rounded,
              iconBg: const Color(0xFFFFE4E6),
              iconColor: const Color(0xFFBE123C),
              title: 'Delete Account Request',
              subtitle: 'Email support to request account deletion',
              onTap: _emailAccountDeletion,
              isLast: true,
            ),

            const SizedBox(height: 20),

            // ── App version footer ───────────────────────────────────────
            const _Footer(),
          ],
        ),
      ),
    );
  }
}

// ─── Hero Card ────────────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final signedIn = state.signedIn;
    final name = state.user?.name ?? 'Doormart Customer';
    final contact = state.user?.email?.isNotEmpty == true
        ? state.user!.email!
        : state.user?.phone ?? 'Guest';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF26522), Color(0xFFE8401A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background watermark
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.storefront_rounded,
              size: 140,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.20),
                            border: Border.all(color: Colors.white38, width: 2),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        if (signedIn)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // Name + contact
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            signedIn ? name : 'Welcome to Doormart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            signedIn
                                ? contact
                                : 'Login to manage orders and addresses',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Info chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.phone_rounded,
                      text: state.user?.phone ?? 'Guest',
                    ),
                    _InfoChip(
                      icon: signedIn
                          ? Icons.verified_rounded
                          : Icons.lock_outline_rounded,
                      text: signedIn ? 'Verified account' : 'Sign in required',
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: _HeroBtn(
                        label: signedIn ? 'Refresh' : 'Login',
                        filled: true,
                        onTap: signedIn
                            ? () => context.read<AppState>().refreshProfile()
                            : () => Navigator.pushNamed(
                                context,
                                LoginScreen.routeName,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeroBtn(
                        label: signedIn ? 'Logout' : 'Register',
                        filled: false,
                        onTap: signedIn
                            ? () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      color: _kOrange,
                                      size: 40,
                                    ),
                                    title: const Text(
                                      'Logout',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: _kTextDark,
                                      ),
                                    ),
                                    content: const Text(
                                      'Are you sure you want to logout?',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: _kTextMid),
                                    ),
                                    actionsAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _kOrange,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Logout'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed != true || !context.mounted) {
                                  return;
                                }
                                await context.read<AppState>().logout();
                                if (!context.mounted) return;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  LoginScreen.routeName,
                                  (_) => false,
                                );
                              }
                            : () => Navigator.pushNamed(
                                context,
                                LoginScreen.routeName,
                              ),
                      ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBtn extends StatefulWidget {
  const _HeroBtn({
    required this.label,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  State<_HeroBtn> createState() => _HeroBtnState();
}

class _HeroBtnState extends State<_HeroBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _s = Tween<double>(
    begin: 1.0,
    end: 0.95,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: widget.filled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: widget.filled ? null : Border.all(color: Colors.white38),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.filled ? _kOrange : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Orders',
            value: '${state.orders.length}',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF4F46E5),
            bg: const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Cart',
            value: '${state.cartCount}',
            icon: Icons.shopping_bag_rounded,
            color: _kOrange,
            bg: _kOrangeLight,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Saved',
            value: '${state.savedAddresses.length}',
            icon: Icons.location_on_rounded,
            color: _kGreen,
            bg: _kGreenLight,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String label, value;
  final IconData icon;
  final Color color, bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _kTextMid,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _kTextMid,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────

class _MenuTile extends StatefulWidget {
  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.isLast = false,
  });
  final IconData icon;
  final Color iconBg, iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  final String? badge;
  final bool isLast;

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _s = Tween<double>(
    begin: 1.0,
    end: 0.97,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(widget.isLast ? 18 : 4),
              bottomRight: Radius.circular(widget.isLast ? 18 : 4),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 22),
                ),

                const SizedBox(width: 14),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(fontSize: 12, color: _kTextMid),
                      ),
                    ],
                  ),
                ),

                // Badge
                if (widget.badge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _kOrangeLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: _kOrange,
                      ),
                    ),
                  ),

                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: _kTextMid,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 110),
  );
  late final Animation<double> _s = Tween<double>(
    begin: 1.0,
    end: 0.96,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFCDD2)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 20),
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _kOrangeLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                color: _kOrange,
                size: 14,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Doormart',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _kOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Version 1',
          style: TextStyle(fontSize: 11, color: _kTextMid),
        ),
        const SizedBox(height: 4),
        const Text(
          '© 2026 Doormart. All rights reserved.',
          style: TextStyle(fontSize: 11, color: _kTextMid),
        ),
      ],
    );
  }
}
