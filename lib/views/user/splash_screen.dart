import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/app_state.dart';
import '../../services/app_update_service.dart';
import 'login_screen.dart';
import '../../features/delivery/screens/delivery_home_screen.dart';
import '../../features/delivery/screens/delivery_status_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../super_admin/super_admin_dashboard_screen.dart';
import '../vendor/vendor_dashboard_screen.dart';
import 'user_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _videoInitFuture;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.asset('assets/animations/doormart_splash.mp4')
          ..setLooping(true)
          ..setVolume(0.0);
    _videoInitFuture = _controller.initialize().then((_) => _controller.play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final state = context.watch<AppState>();
    if (_navigated || !state.initialized) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _finishStartup(state);
    });
  }

  Future<void> _finishStartup(AppState state) async {
    final update = await AppUpdateService(
      apiService: state.apiService,
    ).checkForUpdate();
    if (!mounted) return;
    if (update != null) {
      final shouldLeaveSplash = await showDialog<bool>(
        context: context,
        barrierDismissible: !update.forceUpdate,
        builder: (dialogContext) => PopScope(
          canPop: !update.forceUpdate,
          child: _PremiumUpdateDialog(
            update: update,
            onLater: () => Navigator.pop(dialogContext, false),
            onUpdate: () async {
              await AppUpdateService(
                apiService: state.apiService,
              ).openStore(update);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
          ),
        ),
      );
      if (update.forceUpdate || shouldLeaveSplash == true) return;
    }

    if (!mounted) return;
    final approvalStatus = (state.user?.approvalStatus ?? 'approved')
        .toLowerCase();
    final target = switch (state.user?.role) {
      'delivery_person' =>
        approvalStatus == 'approved'
            ? const DeliveryHomeScreen()
            : const DeliveryStatusScreen(),
      'admin' => const AdminDashboardScreen(),
      'vendor' => const VendorDashboardScreen(),
      'super_admin' => const SuperAdminDashboardScreen(),
      'user' => const UserHomeScreen(),
      _ => const LoginScreen(),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => target));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ColoredBox(
        color: Colors.white,
        child: FutureBuilder<void>(
          future: _videoInitFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done ||
                !_controller.value.isInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE8541A)),
              );
            }

            if (_controller.value.hasError) {
              return Center(
                child: Image.asset(
                  'assets/images/banners/grocery_bag.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                ),
              );
            }

            return Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: VideoPlayer(_controller),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PremiumUpdateDialog extends StatelessWidget {
  const _PremiumUpdateDialog({
    required this.update,
    required this.onLater,
    required this.onUpdate,
  });

  final AppUpdateInfo update;
  final VoidCallback onLater;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.92, end: 1),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE8541A), Color(0xFFC63F12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.asset(
                          'assets/images/doormartLogo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A fresh DoorMart is ready',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      update.forceUpdate
                          ? 'Update now to continue shopping smoothly.'
                          : 'Enjoy a faster, smoother shopping experience.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _VersionPill(
                            label: 'Current',
                            version: update.currentVersion,
                            muted: true,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFE8541A),
                          ),
                        ),
                        Expanded(
                          child: _VersionPill(
                            label: 'New version',
                            version: update.latestVersion,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: update.hasStoreUrl ? onUpdate : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE8541A),
                          disabledBackgroundColor: const Color(0xFFE5E7EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          update.hasStoreUrl
                              ? 'Update now'
                              : 'Store link unavailable',
                        ),
                      ),
                    ),
                    if (!update.forceUpdate) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: onLater,
                        child: const Text(
                          'Maybe later',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
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

class _VersionPill extends StatelessWidget {
  const _VersionPill({
    required this.label,
    required this.version,
    this.muted = false,
  });
  final String label;
  final String version;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF3F4F6) : const Color(0xFFFFF0EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: muted ? const Color(0xFFE5E7EB) : const Color(0xFFFFD5C6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8A9490),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'v$version',
            style: TextStyle(
              color: muted ? const Color(0xFF374151) : const Color(0xFFE8541A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
