import 'constants/api_constants.dart';

class AppConstants {
  static const appName = 'Doormart Delivery';
  static String get apiBaseUrl => ApiConstants.baseUrl;
  static String get socketUrl => ApiConstants.socketUrl;
  static const maxCarouselItems = 12;
  static const carouselAutoSlideSeconds = 3;
}

class UserRoles {
  static const user = 'user';
  static const delivery = 'delivery';
  static const admin = 'admin';
  static const superAdmin = 'super_admin';
}
