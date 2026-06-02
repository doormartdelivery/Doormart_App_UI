import 'package:flutter/foundation.dart';

import '../models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  final List<OrderModel> orders = [];

  void add(OrderModel order) {
    orders.insert(0, order);
    notifyListeners();
  }
}
