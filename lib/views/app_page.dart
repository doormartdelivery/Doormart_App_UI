import 'package:flutter/material.dart';

import '../mascot/walking_mascot_widget.dart';
import '../widgets/bottom_nav_bar.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.children,
    this.actions,
    this.bottomNavIndex,
    this.leading,
    this.drawer,
    this.scaffoldKey,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;
  final int? bottomNavIndex;
  final Widget? leading;
  final Widget? drawer;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomNavPadding = bottomNavIndex == null
        ? 0.0
        : kBottomNavigationBarHeight;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      key: scaffoldKey,
      drawer: drawer,
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: const Color(0xFFF6F6F6),
        surfaceTintColor: const Color(0xFFF6F6F6),
        elevation: 0,
        title: Text(title),
        actions: actions,
        leading: leading,
      ),
      body: SafeArea(
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + bottomInset + bottomNavPadding,
          ),
          children: [
            ...children,
            const SizedBox(height: 12),
            const WalkingMascotWidget(),
          ],
        ),
      ),
      bottomNavigationBar: bottomNavIndex == null
          ? null
          : BottomNavBar(
              index: bottomNavIndex!,
              onTap: (index) => BottomNavBar.navigate(context, index),
            ),
    );
  }
}
