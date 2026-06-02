import 'package:flutter/material.dart';

import '../mascot/walking_mascot_widget.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          children: [
            ...children,
            const SizedBox(height: 12),
            const WalkingMascotWidget(),
          ],
        ),
      ),
    );
  }
}
