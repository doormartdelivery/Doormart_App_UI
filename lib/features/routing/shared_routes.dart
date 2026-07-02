import 'package:flutter/material.dart';

import '../../features/auth/auth_gate.dart';
import '../../views/access_denied_screen.dart';

class SharedRoutes {
  static Map<String, WidgetBuilder> get routes => {
    AuthGate.routeName: (_) => const AuthGate(),
    AccessDeniedScreen.routeName: (_) => const AccessDeniedScreen(),
  };
}
