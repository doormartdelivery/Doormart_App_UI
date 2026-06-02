import 'product_model.dart';

class CartModel {
  const CartModel({required this.product, required this.quantity});
  final ProductModel product;
  final int quantity;
  double get total => product.price * quantity;
}
