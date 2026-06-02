import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class AddEditAddressScreen extends StatelessWidget {
  const AddEditAddressScreen({super.key});
  static const routeName = '/address/edit';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Add Address',
    icon: Icons.add_location_alt,
    description: 'Address form with validation and map-friendly fields.',
  );
}
