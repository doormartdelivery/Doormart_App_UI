import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/app_state.dart';
import '../views/user/cart_screen.dart';
import '../views/user/notification_screen.dart';
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
      1 => NotificationScreen.routeName,
      2 => CartScreen.routeName,
      3 => WishlistScreen.routeName,
      4 => ProfileScreen.routeName,
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
    return Consumer<AppState>(
      builder: (context, state, _) {
        if (state.user?.role == UserRoles.deliveryPerson) {
          return const SizedBox.shrink();
        }

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // Bottom Nav Bar with notch
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: _NotchClipper(),
                child: Container(
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _NavItem(
                        icon: Icons.home,
                        label: 'Home',
                        isSelected: index == 0,
                        onTap: () => onTap(0),
                      ),
                      _NavItem(
                        icon: Icons.notifications_none_rounded,
                        label: 'Alerts',
                        isSelected: index == 1,
                        onTap: () => onTap(1),
                      ),
                      // Center spacer for the FAB
                      const SizedBox(width: 72),
                      _NavItem(
                        icon: Icons.favorite_border,
                        label: 'Wishlist',
                        isSelected: index == 3,
                        onTap: () => onTap(3),
                      ),
                      _NavItem(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        isSelected: index == 4,
                        onTap: () => onTap(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Floating Cart Button (centered, raised above the bar)
            Positioned(
              top: -28,
              child: GestureDetector(
                onTap: () => onTap(2),
                child: Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8541A),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE8541A).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      if (state.cartCount > 0)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom clipper to create a smooth curved notch in the center
class _NotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const notchRadius = 42.0;
    const notchCenter = 0.5;
    final centerX = size.width * notchCenter;

    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(centerX - notchRadius - 18, 0);

    // Left curve into notch
    path.quadraticBezierTo(
      centerX - notchRadius,
      0,
      centerX - notchRadius + 4,
      notchRadius * 0.5,
    );

    // Bottom of notch arc
    path.arcToPoint(
      Offset(centerX + notchRadius - 4, notchRadius * 0.5),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );

    // Right curve out of notch
    path.quadraticBezierTo(
      centerX + notchRadius,
      0,
      centerX + notchRadius + 18,
      0,
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(_NotchClipper oldClipper) => false;
}

// Individual nav item widget
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? const Color(0xFFE8541A)
                  : const Color(0xFFAAAAAA),
            ),
          ],
        ),
      ),
    );
  }
}
