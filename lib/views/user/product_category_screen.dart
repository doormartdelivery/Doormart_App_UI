import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/network_image_url.dart';
import '../../models/category_model.dart';
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
            final categories = snapshot.data!
                .cast<Map<String, dynamic>>()
                .map(CategoryModel.fromJson)
                .toList();
            if (categories.isEmpty) {
              return const Text('No categories available');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.92,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final category = categories[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pushNamed(
                    context,
                    ProductListScreen.routeName,
                    arguments: category.name,
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Center(
                              child: NetworkImageUrl.normalize(category.imageUrl).startsWith('assets/')
                                  ? Image.asset(NetworkImageUrl.normalize(category.imageUrl), fit: BoxFit.contain)
                                  : NetworkImageUrl.normalize(category.imageUrl).startsWith('http')
                                      ? Image.network(
                                          NetworkImageUrl.normalize(category.imageUrl),
                                          fit: BoxFit.contain,
                                        )
                                      : const Icon(
                                          Icons.category,
                                          size: 44,
                                        ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            category.description.isEmpty
                                ? 'Browse products'
                                : category.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
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
