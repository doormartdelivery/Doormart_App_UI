import 'package:flutter/material.dart';

import '../../providers/product_provider.dart';
import '../app_page.dart';

class ManageProductsScreen extends StatelessWidget {
  const ManageProductsScreen({super.key});

  static const routeName = '/admin/products';

  @override
  Widget build(BuildContext context) {
    final products = ProductProvider().products;
    return AppPage(
      title: 'Manage products',
      actions: [
        IconButton(
          tooltip: 'Add product',
          onPressed: () {},
          icon: const Icon(Icons.add_box),
        ),
      ],
      children: products
          .map(
            (product) => ListTile(
              leading: const Icon(Icons.inventory),
              title: Text(product.name),
              subtitle: Text(
                'Stock ${product.stock} | Cost Rs ${product.cost}',
              ),
              trailing: const Icon(Icons.edit),
            ),
          )
          .toList(),
    );
  }
}
