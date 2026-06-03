import 'package:flutter/material.dart';

import '../../views/access_denied_screen.dart';
import '../../views/select_role_screen.dart';

class SharedRoutes {
  static Map<String, WidgetBuilder> get routes => {
    SelectRoleScreen.routeName: (_) => const SelectRoleScreen(),
    AccessDeniedScreen.routeName: (_) => const AccessDeniedScreen(),
  };
}
