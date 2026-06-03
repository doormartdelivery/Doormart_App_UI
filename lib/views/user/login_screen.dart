import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../role_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    return const RoleLoginScreen(
      title: 'Customer Login',
      subtitle:
          'Use email + password or email OTP to reach your customer dashboard.',
      role: UserRoles.user,
      allowOtp: true,
      allowPhonePassword: false,
      allowEmailPassword: true,
    );
  }
}
