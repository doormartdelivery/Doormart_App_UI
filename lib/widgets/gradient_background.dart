import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7FAF4),
        //  gradient: LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
        //   stops: [0.0, 0.5, 1.0],
        // ),
      ),
      child: child,
    );
  }
}
