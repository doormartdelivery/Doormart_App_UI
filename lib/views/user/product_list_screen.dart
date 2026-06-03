import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/product_card.dart';
import '../../widgets/toast_widget.dart';
import '../app_page.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  static const routeName = '/products';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Products',
      bottomNavIndex: 1,
      children: [
        Consumer<AppState>(
          builder: (context, state, _) => TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search groceries',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) => state.loadProducts(search: value),
          ),
        ),
        const SizedBox(height: 12),
        Consumer<AppState>(
          builder: (context, state, _) {
            if (state.loading && state.products.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.error != null && state.products.isEmpty) {
              return Text(state.error!);
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.products.length,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) => ProductCard(
                product: state.products[index],
                onAdd: () async {
                  final added = await state.addToCart(state.products[index]);
                  if (!context.mounted) return;
                  showToast(
                    context,
                    added
                        ? '${state.products[index].name} added to cart'
                        : state.error ?? 'Please login first',
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
