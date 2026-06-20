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
                              child: _CategoryImage(imageUrl: category.imageUrl),
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

class _CategoryImage extends StatelessWidget {
  const _CategoryImage({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final normalized = NetworkImageUrl.normalize(imageUrl);
    debugPrint('Cloudinary Image URL: $normalized');

    if (normalized.isEmpty) {
      return const Icon(Icons.category, size: 44);
    }

    if (normalized.startsWith('assets/')) {
      return Image.asset(
        normalized,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image Load Error (asset): $error');
          return const Icon(Icons.broken_image, size: 44);
        },
      );
    }

    if (normalized.startsWith('http')) {
      return Image.network(
        normalized.trim(),
        fit: BoxFit.contain,
        gaplessPlayback: true,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Image Load Error: $error');
          debugPrint('Image URL Failed: $normalized');
          return const Icon(Icons.broken_image, size: 44);
        },
      );
    }

    debugPrint('Malformed image URL: $normalized');
    return const Icon(Icons.broken_image, size: 44);
  }
}
