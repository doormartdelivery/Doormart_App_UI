import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/product_card.dart';
import '../app_page.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  static const routeName = '/products';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Products',
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
                onAdd: () {
                  state.addToCart(state.products[index]);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${state.products[index].name} added'),
                    ),
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
