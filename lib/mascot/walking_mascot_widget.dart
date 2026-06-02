import 'package:flutter/material.dart';

class WalkingMascotWidget extends StatefulWidget {
  const WalkingMascotWidget({super.key});

  @override
  State<WalkingMascotWidget> createState() => _WalkingMascotWidgetState();
}

class _WalkingMascotWidgetState extends State<WalkingMascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Align(
          alignment: Alignment(-1 + (_controller.value * 2), 0),
          child: Semantics(
            label: 'Walking grocery mascot',
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.child_care, size: 22),
                Icon(Icons.shopping_bag, size: 18),
                Icon(Icons.local_grocery_store, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
