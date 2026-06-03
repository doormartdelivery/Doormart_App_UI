import 'constants.dart';

class RoleAccess {
  static const _customerOnlyRoutes = {
    '/',
    '/cart',
    '/checkout',
    '/address',
    '/address/edit',
    '/payment',
    '/order-success',
    '/live-order-tracking',
    '/my-orders',
    '/order-details',
    '/scheduled-orders',
    '/notifications',
    '/profile',
    '/profile/edit',
    '/settings',
  };

  static bool canAccessRoute(String? role, String routeName) {
    if (routeName == '/login' ||
        routeName == '/select-role' ||
        routeName == '/signup' ||
        routeName == '/splash') {
      return true;
    }
    if (routeName.startsWith('/super-admin')) {
      return role == UserRoles.superAdmin || routeName == '/super-admin/login';
    }
    if (routeName.startsWith('/admin')) {
      return role == UserRoles.admin ||
          role == UserRoles.superAdmin ||
          routeName == '/admin/login';
    }
    if (routeName.startsWith('/delivery')) {
      return role == UserRoles.deliveryPerson || routeName == '/delivery/login';
    }
    if (_customerOnlyRoutes.contains(routeName)) {
      return role == null || role == UserRoles.user;
    }
    return true;
  }

  static String dashboardForRole(String? role) {
    switch (role) {
      case UserRoles.deliveryPerson:
        return '/delivery';
      case UserRoles.admin:
        return '/admin';
      case UserRoles.superAdmin:
        return '/super-admin';
      case UserRoles.user:
      default:
        return '/';
    }
  }
}
