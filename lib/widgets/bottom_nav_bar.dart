import 'package:flutter/material.dart';

import '../views/user/cart_screen.dart';
import '../views/user/wishlist_screen.dart';
import '../views/user/profile_screen.dart';
import '../views/user/user_home_screen.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key, required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static void navigate(BuildContext context, int index) {
    final routeName = switch (index) {
      0 => UserHomeScreen.routeName,
      1 => WishlistScreen.routeName,
      2 => CartScreen.routeName,
      3 => ProfileScreen.routeName,
      _ => UserHomeScreen.routeName,
    };

    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => route.settings.name == UserHomeScreen.routeName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.favorite), label: 'Favorites'),
        NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
