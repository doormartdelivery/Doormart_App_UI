import 'package:flutter/material.dart';

class GroceryBabyMascot extends StatefulWidget {
  const GroceryBabyMascot({super.key});

  @override
  State<GroceryBabyMascot> createState() => _GroceryBabyMascotState();
}

class _GroceryBabyMascotState extends State<GroceryBabyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
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
      height: 54,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Align(
          alignment: Alignment(-1 + (_controller.value * 2), 0),
          child: const Text('Baby Grocer', style: TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
