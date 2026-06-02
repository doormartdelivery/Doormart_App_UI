import 'package:flutter/material.dart';
import '../feature_placeholder_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  static const routeName = '/search';
  @override
  Widget build(BuildContext context) => const FeaturePlaceholderScreen(
    title: 'Search',
    icon: Icons.search,
    description: 'Search groceries with filters and sort options.',
  );
}
