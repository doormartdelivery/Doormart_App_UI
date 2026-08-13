import 'package:flutter/material.dart';
import '../admin/manage_products_screen.dart';

class SuperAdminProductsScreen extends StatelessWidget {
  const SuperAdminProductsScreen({super.key});
  static const routeName = '/super-admin/products';
  @override
  Widget build(BuildContext context) => const ManageProductsScreen();
}
