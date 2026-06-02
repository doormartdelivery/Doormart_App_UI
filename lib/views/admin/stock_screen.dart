import 'package:flutter/material.dart';

import '../../providers/product_provider.dart';
import '../app_page.dart';

class StockScreen extends StatelessWidget {
  const StockScreen({super.key});

  static const routeName = '/admin/stock';

  @override
  Widget build(BuildContext context) {
    return AppPage(
      title: 'Stock',
      children: ProductProvider().products
          .map(
            (product) => ListTile(
              leading: Icon(
                product.stock < 50 ? Icons.warning : Icons.check_circle,
              ),
              title: Text(product.name),
              subtitle: Text('${product.stock} units available'),
            ),
          )
          .toList(),
    );
  }
}
