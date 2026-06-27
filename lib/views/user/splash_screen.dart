import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../providers/app_state.dart';
import '../../features/auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const routeName = '/splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _videoInitFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(
      'assets/animations/doormart_splash.mp4',
    )
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
    if (!state.initialized) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AuthGate.routeName,
      );
    });
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
