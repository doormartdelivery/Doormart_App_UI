import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  final List<ProductModel> products = const [
    ProductModel(
      id: 'p1',
      name: 'Fresh Tomato',
      category: 'Vegetables',
      price: 38,
      cost: 25,
      stock: 120,
      imageUrl: 'assets/images/products/tomato.png',
    ),
    ProductModel(
      id: 'p2',
      name: 'A2 Milk',
      category: 'Dairy',
      price: 72,
      cost: 54,
      stock: 42,
      imageUrl: 'assets/images/products/milk.png',
    ),
    ProductModel(
      id: 'p3',
      name: 'Basmati Rice',
      category: 'Staples',
      price: 149,
      cost: 103,
      stock: 80,
      imageUrl: 'assets/images/products/rice.png',
    ),
  ];
}
