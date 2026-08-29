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
    required this.quantities,
    required this.paymentMethod,
    required this.total,
    required this.status,
    required this.createdAt,
    this.vendorId = 'main',
    this.scheduledFor,
    this.address = '',
    this.customerName = '',
    this.customerAddress = '',
    this.customerPhone = '',
    this.deliveryPersonId,
    this.deliveryPersonName,
    this.deliveryPersonPhone,
    this.deliveryAcceptedAt,
    this.acceptedAt,
    this.deliveredAt,
    this.deliveryOtp,
  });

  final String id;
  final List<ProductModel> products;
  final List<int> quantities;
  final String paymentMethod;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String vendorId;
  final DateTime? scheduledFor;
  final String address;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final String? deliveryPersonPhone;
  final DateTime? deliveryAcceptedAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
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

  String get orderNumber => displayOrderId;

  String get deliveryOtpDisplay {
    if ((deliveryOtp ?? '').isNotEmpty) return deliveryOtp!;
    return id
        .replaceAll(RegExp(r'[^0-9]'), '')
        .substring(
          id.replaceAll(RegExp(r'[^0-9]'), '').length >= 6
              ? id.replaceAll(RegExp(r'[^0-9]'), '').length - 6
              : 0,
        )
        .padLeft(6, '0');
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final productsJson = (json['products'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final deliveryPerson = json['deliveryPerson'];
    final deliveryPersonMap = deliveryPerson is Map<String, dynamic>
        ? deliveryPerson
        : null;
    final rawId = json['_id'] ?? json['id'] ?? '';
    final rawAddress = json['address'];
    final addressText = rawAddress is String
        ? rawAddress
        : rawAddress is Map<String, dynamic>
        ? [rawAddress['line1'], rawAddress['city'], rawAddress['pincode']]
              .whereType<String>()
              .where((value) => value.trim().isNotEmpty)
              .join(', ')
        : '';

    return OrderModel(
      id: rawId?.toString() ?? '',
      products: productsJson
          .map(
            (item) => ProductModel(
              id:
                  item['productId']?.toString() ??
                  item['product']?.toString() ??
                  '',
              name: item['name']?.toString() ?? 'Product',
              category: item['category']?.toString() ?? 'Grocery',
              price: (item['price'] as num? ?? 0).toDouble(),
              cost: 0,
              stock: 0,
              imageUrl: item['imageUrl']?.toString() ?? '',
              unit: item['unit']?.toString() ?? 'item',
            ),
          )
          .toList(),
      quantities: productsJson
          .map((item) => (item['quantity'] as num? ?? 1).toInt())
          .toList(),
      paymentMethod:
          (json['paymentMethod'] ??
                  json['paymentType'] ??
                  json['paymentMode'] ??
                  'cod')
              .toString()
              .toLowerCase(),
      total: (json['total'] as num? ?? 0).toDouble(),
      status: _statusFromJson(json['status']?.toString()),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      vendorId: json['vendorId']?.toString() ?? 'main',
      scheduledFor: _parseDateTime(json['scheduledFor']),
      address: addressText,
      customerName: json['customerName']?.toString() ?? '',
      customerAddress: json['customerAddress']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      deliveryPersonId: deliveryPersonMap == null
          ? deliveryPerson?.toString()
          : deliveryPersonMap['_id']?.toString() ??
                deliveryPersonMap['id']?.toString(),
      deliveryPersonName: deliveryPersonMap?['name']?.toString(),
      deliveryPersonPhone:
          deliveryPersonMap?['phone']?.toString() ??
          json['deliveryPersonPhone']?.toString(),
      deliveryAcceptedAt: _parseDateTime(json['deliveryAcceptedAt']),
      acceptedAt: _parseDateTime(json['acceptedAt']),
      deliveredAt: _parseDateTime(json['deliveredAt']),
      deliveryOtp: json['deliveryOtp']?.toString(),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  return parsed.toLocal();
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
