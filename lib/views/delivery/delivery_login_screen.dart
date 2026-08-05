import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../role_login_screen.dart';

class DeliveryLoginScreen extends StatelessWidget {
  const DeliveryLoginScreen({super.key});
  static const routeName = '/delivery/login';
  @override
  Widget build(BuildContext context) => const RoleLoginScreen(
    title: 'Delivery Login',
    subtitle: 'Delivery partners sign in with phone or email and password.',
    role: UserRoles.deliveryPerson,
    allowPhonePassword: true,
    allowEmailPassword: true,
  );
}
