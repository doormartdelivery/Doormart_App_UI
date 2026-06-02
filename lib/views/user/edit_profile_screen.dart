import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});
  static const routeName = '/profile/edit';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Edit Profile',
    icon: Icons.edit,
    description: 'Update name, phone, email, and preferences.',
  );
}
