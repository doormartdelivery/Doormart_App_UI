import 'product_model.dart';

enum OrderStatus {
  placed,
  accepted,
  packed,
  assigned,
  deliveryAccepted,
  pickedUp,
  delivered,
  cancelled,
}

class OrderModel {
  const OrderModel({
    required this.id,
    required this.products,
    required this.total,
    required this.status,
    required this.createdAt,
    this.scheduledFor,
    this.address = '',
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryAcceptedAt,
    this.deliveryOtp,
  });

  final String id;
  final List<ProductModel> products;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final String address;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final DateTime? deliveryAcceptedAt;
  final String? deliveryOtp;

  String get displayOrderId {
    final source = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (source.isEmpty) return 'DMD-000-000';

    final tail = source.length >= 6
        ? source.substring(source.length - 6)
        : source.padLeft(6, '0');
    final first = tail.substring(0, 3);
    final second = tail.substring(3, 6);
    return 'DMD-$first-$second';
  }

  String get deliveryOtpDisplay {
    if ((deliveryOtp ?? '').isNotEmpty) return deliveryOtp!;
    return id.replaceAll(RegExp(r'[^0-9]'), '').substring(
      id.replaceAll(RegExp(r'[^0-9]'), '').length >= 6
          ? id.replaceAll(RegExp(r'[^0-9]'), '').length - 6
          : 0,
    ).padLeft(6, '0');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final productsJson = (json['products'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final deliveryPerson = json['deliveryPerson'];
    final deliveryPersonMap = deliveryPerson is Map<String, dynamic>
        ? deliveryPerson
        : null;

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
              imageUrl: item['imageUrl'] as String? ?? '',
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
      deliveryPersonId: deliveryPersonMap == null
          ? deliveryPerson as String?
          : deliveryPersonMap['_id'] as String? ?? deliveryPersonMap['id'] as String?,
      deliveryPersonName: deliveryPersonMap?['name'] as String?,
      deliveryAcceptedAt:
          DateTime.tryParse(json['deliveryAcceptedAt'] as String? ?? ''),
      deliveryOtp: json['deliveryOtp'] as String?,
    );
  }
}

OrderStatus _statusFromJson(String? status) {
  return switch (status) {
    'WAITING_FOR_ACCEPT' || 'placed' => OrderStatus.placed,
    'ACCEPTED' || 'accepted' => OrderStatus.accepted,
    'PACKED' || 'packed' => OrderStatus.packed,
    'ASSIGNED' || 'assigned' => OrderStatus.assigned,
    'DELIVERY_ACCEPTED' || 'delivery_accepted' => OrderStatus.deliveryAccepted,
    'PICKED_UP' || 'picked_up' => OrderStatus.pickedUp,
    'DELIVERED' || 'delivered' => OrderStatus.delivered,
    'CANCELLED' || 'cancelled' => OrderStatus.cancelled,
    _ => OrderStatus.placed,
  };
}
