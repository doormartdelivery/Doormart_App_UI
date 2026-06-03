import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../app_page.dart';
import 'product_list_screen.dart';

class ProductCategoryScreen extends StatelessWidget {
  const ProductCategoryScreen({super.key});
  static const routeName = '/categories';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Categories',
      bottomNavIndex: 1,
      children: [
        FutureBuilder<List<dynamic>>(
          future: context.read<AppState>().categories(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final categories = snapshot.data!;
            if (categories.isEmpty) {
              return const Text('No categories available');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final category = categories[index] as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.category),
                    title: Text(category['name'] as String),
                    subtitle: Text('${category['productCount'] ?? 0} products'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      ProductListScreen.routeName,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
