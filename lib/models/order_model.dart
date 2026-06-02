import 'product_model.dart';

enum OrderStatus { placed, accepted, pickedUp, delivered }

class OrderModel {
  const OrderModel({
    required this.id,
    required this.products,
    required this.total,
    required this.status,
    required this.createdAt,
    this.scheduledFor,
    this.address = '',
  });

  final String id;
  final List<ProductModel> products;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String address;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final productsJson = (json['products'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return OrderModel(
      id: json['_id'] as String? ?? json['id'] as String,
      products: productsJson
          .map(
            (item) => ProductModel(
              id:
                  item['productId'] as String? ??
                  item['product'] as String? ??
                  '',
              name: item['name'] as String? ?? 'Product',
              category: item['category'] as String? ?? 'Grocery',
              price: (item['price'] as num? ?? 0).toDouble(),
              cost: 0,
              stock: 0,
              imageUrl: '',
              unit: 'item',
            ),
          )
          .toList(),
      total: (json['total'] as num? ?? 0).toDouble(),
      status: _statusFromJson(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      scheduledFor: DateTime.tryParse(json['scheduledFor'] as String? ?? ''),
      address: json['address'] as String? ?? '',
    );
  }
}

OrderStatus _statusFromJson(String? status) {
  return switch (status) {
    'accepted' => OrderStatus.accepted,
    'picked_up' => OrderStatus.pickedUp,
    'delivered' => OrderStatus.delivered,
    _ => OrderStatus.placed,
  };
}
