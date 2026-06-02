import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

class CartProvider extends ChangeNotifier {
  final List<ProductModel> items = [];

  double get total => items.fold(0, (sum, item) => sum + item.price);

  void add(ProductModel product) {
    items.add(product);
    notifyListeners();
  }

  void remove(ProductModel product) {
    items.remove(product);
    notifyListeners();
  }
}
