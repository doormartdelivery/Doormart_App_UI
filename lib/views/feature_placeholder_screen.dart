import 'package:flutter/material.dart';

import '../widgets/empty_state_widget.dart';
import '../widgets/error_state_widget.dart';
import '../widgets/loading_widget.dart';
import 'app_page.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.loading = false,
    this.error,
  });

  final String title;
  final IconData icon;
  final String description;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    Widget state;
    if (loading) {
      state = const LoadingWidget();
    } else if (error != null) {
      state = ErrorStateWidget(message: error!);
    } else {
      state = EmptyStateWidget(message: description);
    }

    return AppPage(
      title: title,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(icon, size: 42),
                const SizedBox(height: 12),
                state,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
