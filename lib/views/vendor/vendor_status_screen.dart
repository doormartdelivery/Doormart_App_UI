import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import 'vendor_register_screen.dart';

const _kOrange = Color(0xFFE8541A);
const _kOrangeLight = Color(0xFFFFF0EB);
const _kBg = Color(0xFFFFF6F0);
const _kTextDark = Color(0xFF1A1A1A);

class VendorStatusScreen extends StatelessWidget {
  const VendorStatusScreen({super.key});

  static const routeName = '/vendor/status';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            const _StatusTopBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Consumer<AppState>(
                    builder: (context, state, _) {
                      final user = state.user;
                      final vendor = state.vendor;
                      final status =
                          user?.approvalStatus ??
                          vendor?.approvalStatus ??
                          'pending';
                      final rejectionReason =
                          user?.rejectionReason ?? vendor?.rejectionReason ?? '';
                      final title = switch (status) {
                        'approved' => 'Vendor Account Approved',
                        'rejected' => 'Vendor Registration Rejected',
                        'suspended' => 'Vendor Account Suspended',
                        _ => 'Account Under Review',
                      };
                      final message = switch (status) {
                        'approved' =>
                          'Congratulations! Your DoorMart vendor account has been approved. You can now access your Vendor Dashboard.',
                        'rejected' =>
                          rejectionReason.isEmpty
                              ? 'Your vendor registration has been rejected. Please update your details and resubmit for approval.'
                              : rejectionReason,
                        'suspended' =>
                          rejectionReason.isEmpty
                              ? 'Your vendor account is suspended. Please contact support for assistance.'
                              : rejectionReason,
                        _ =>
                          'Your vendor registration is currently being reviewed by the DoorMart team. You will receive access after Super Admin approval.',
                      };

                      return Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 560),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 30,
                              offset: Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: _kOrangeLight,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              child: Icon(
                                _statusIcon(status),
                                color: _kOrange,
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.55,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            if (rejectionReason.isNotEmpty &&
                                status == 'rejected') ...[
                              const SizedBox(height: 16),
                              _ReasonBox(reason: rejectionReason),
                            ],
                            const SizedBox(height: 24),
                            if (status == 'approved')
                              _ActionButton(
                                label: 'Go to Dashboard',
                                filled: true,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamedAndRemoveUntil(
                                  '/vendor/dashboard',
                                  (route) => false,
                                ),
                              )
                            else if (status == 'pending') ...[
                              _ActionButton(
                                label: 'Refresh Status',
                                filled: true,
                                onPressed: () async {
                                  await context
                                      .read<AppState>()
                                      .refreshVendorStatus();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Status refreshed'),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _ActionButton(
                                label: 'Contact Support',
                                filled: false,
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Contact support at support@doormart.com',
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _ActionButton(
                                label: 'Logout',
                                filled: false,
                                onPressed: () async {
                                  await context.read<AppState>().logout();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/vendor/login',
                                    (route) => false,
                                  );
                                },
                              ),
                            ] else if (status == 'rejected') ...[
                              _ActionButton(
                                label: 'Refresh Status',
                                filled: true,
                                onPressed: () async {
                                  await context
                                      .read<AppState>()
                                      .refreshVendorStatus();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Status refreshed'),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              if (status == 'rejected')
                                _ActionButton(
                                  label: 'Update Vendor Details',
                                  filled: false,
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(VendorRegisterScreen.routeName),
                                ),
                              const SizedBox(height: 12),
                              _ActionButton(
                                label: 'Resubmit for Approval',
                                filled: true,
                                onPressed: () => Navigator.of(
                                  context,
                                ).pushNamed(VendorRegisterScreen.routeName),
                              ),
                              const SizedBox(height: 12),
                              _ActionButton(
                                label: 'Contact Support',
                                filled: false,
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Contact support at support@doormart.com',
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _ActionButton(
                                label: 'Logout',
                                filled: false,
                                onPressed: () async {
                                  await context.read<AppState>().logout();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/vendor/login',
                                    (route) => false,
                                  );
                                },
                              ),
                            ] else ...[
                              _ActionButton(
                                label: 'Contact Support',
                                filled: false,
                                onPressed: () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Contact support at support@doormart.com',
                                        ),
                                      ),
                                    ),
                              ),
                              const SizedBox(height: 12),
                              _ActionButton(
                                label: 'Logout',
                                filled: false,
                                onPressed: () async {
                                  await context.read<AppState>().logout();
                                  if (!context.mounted) return;
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/vendor/login',
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      );
                    },
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

class _StatusTopBar extends StatelessWidget {
  const _StatusTopBar();

  @override
  Widget build(BuildContext context) {
    void goBack() {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
        return;
      }
      navigator.pushReplacementNamed('/vendor/login');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: goBack,
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
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 26,
                color: _kOrange,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Account Status',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: _kTextDark,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonBox extends StatelessWidget {
  const _ReasonBox({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kOrangeLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kOrange.withValues(alpha: 0.35)),
      ),
      child: Text(
        reason,
        style: const TextStyle(
          color: _kOrange,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: filled
          ? FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPressed,
              child: Text(label),
            )
          : OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _kOrange,
                side: const BorderSide(color: _kOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: onPressed,
              child: Text(label),
            ),
    );
  }
}

IconData _statusIcon(String status) {
  switch (status) {
    case 'approved':
      return Icons.verified_rounded;
    case 'rejected':
      return Icons.cancel_rounded;
    case 'suspended':
      return Icons.pause_circle_rounded;
    default:
      return Icons.hourglass_top_rounded;
  }
}