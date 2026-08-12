import 'package:flutter/material.dart';

import '../../views/vendor/vendor_dashboard_screen.dart';
import '../../views/vendor/vendor_login_screen.dart';
import '../../views/vendor/vendor_registration_success_screen.dart';
import '../../views/vendor/vendor_register_screen.dart';
import '../../views/vendor/vendor_status_screen.dart';

class VendorRoutes {
  static Map<String, WidgetBuilder> get routes => {
    VendorLoginScreen.routeName: (_) => const VendorLoginScreen(),
    VendorRegisterScreen.routeName: (_) => const VendorRegisterScreen(),
    VendorRegistrationSuccessScreen.routeName: (_) =>
        const VendorRegistrationSuccessScreen(),
    VendorStatusScreen.routeName: (_) => const VendorStatusScreen(),
    VendorDashboardScreen.routeName: (_) => const VendorDashboardScreen(),
  };
}
