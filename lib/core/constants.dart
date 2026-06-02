class AppConstants {
  static const appName = 'Doormart Delivery';
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );
  static const socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );
  static const maxCarouselItems = 12;
  static const carouselAutoSlideSeconds = 3;
}

class UserRoles {
  static const user = 'user';
  static const delivery = 'delivery';
  static const admin = 'admin';
  static const superAdmin = 'super_admin';
}
