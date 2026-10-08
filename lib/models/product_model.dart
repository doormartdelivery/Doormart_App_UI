import '../core/utils/network_image_url.dart';

class ProductUnitVariant {
  const ProductUnitVariant({
    required this.unit,
    required this.price,
    required this.discountCost,
    required this.stock,
  });

  final String unit;
  final double price;
  final double discountCost;
  final int stock;

  factory ProductUnitVariant.fromJson(Map<String, dynamic> json) {
    final discountCost =
        (json['discountCost'] as num?)?.toDouble() ??
        (json['discount_cost'] as num?)?.toDouble() ??
        (json['mrp'] as num?)?.toDouble() ??
        (json['cost'] as num?)?.toDouble() ??
        0;
    return ProductUnitVariant(
      unit: json['unit'] as String? ?? 'item',
      price: (json['price'] as num? ?? 0).toDouble(),
      discountCost: discountCost,
      stock: (json['stock'] as num? ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'unit': unit,
    'price': price,
    'discountCost': discountCost,
    'stock': stock,
  };
}

class ProductReviewModel {
  const ProductReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.userName,
    required this.userAvatarUrl,
    required this.createdAt,
  });

  final String id;
  final double rating;
  final String comment;
  final String userName;
  final String userAvatarUrl;
  final DateTime? createdAt;

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      comment: json['comment'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Customer',
      userAvatarUrl: NetworkImageUrl.normalize(
        json['userAvatarUrl'] as String?,
      ),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }
}

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    required this.imageUrl,
    this.vendorId = 'main',
    this.supplierName = '',
    this.supplierCity = '',
    this.supplierLogo = '',
    this.description = '',
    this.dashboardSection = 'daily_essentials',
    this.rating = 0,
    this.ratingCount = 0,
    this.mrp = 0,
    this.unit = 'item',
    this.unitVariants = const [],
    this.vendorIsOpen,
    this.vendorTodayOpenTime,
    this.vendorTodayCloseTime,
    this.tax = 0,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double cost;
  final int stock;
  final String imageUrl;
  final String vendorId;
  final String supplierName;
  final String supplierCity;
  final String supplierLogo;
  final String description;
  final String dashboardSection;
  final double rating;
  final int ratingCount;
  final double mrp;
  final String unit;
  final List<ProductUnitVariant> unitVariants;
  final bool? vendorIsOpen;
  final String? vendorTodayOpenTime;
  final String? vendorTodayCloseTime;
  final double tax;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final stockQuantity = (json['stockQuantity'] as num?)?.toInt();
    final stock = (json['stock'] as num?)?.toInt();
    final stockValue = (stockQuantity != null && stockQuantity > 0)
        ? stockQuantity
        : (stock ?? 0);
    return ProductModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      cost: (json['cost'] as num? ?? 0).toDouble(),
      stock: (stockValue as num).toInt(),
      imageUrl: NetworkImageUrl.normalize(json['imageUrl'] as String?),
      vendorId: json['vendorId'] as String? ?? 'main',
      supplierName: json['supplierName'] as String? ?? '',
      supplierCity: json['supplierCity'] as String? ?? '',
      supplierLogo: NetworkImageUrl.normalize(json['supplierLogo'] as String?),
      description: json['description'] as String? ?? '',
      dashboardSection:
          json['dashboardSection'] as String? ?? 'daily_essentials',
      rating: (json['rating'] as num? ?? 0).toDouble(),
      ratingCount: (json['ratingCount'] as num? ?? 0).toInt(),
      mrp: (json['mrp'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'item',
      unitVariants: _parseUnitVariants(json),
      vendorIsOpen: json['vendorIsOpen'] is bool
          ? json['vendorIsOpen'] as bool
          : null,
      vendorTodayOpenTime: json['vendorTodayOpenTime']?.toString(),
      vendorTodayCloseTime: json['vendorTodayCloseTime']?.toString(),
      tax: (json['tax'] as num? ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'productId': id,
    'name': name,
    'category': category,
    'price': price,
    'cost': cost,
    'stock': stock,
    'imageUrl': imageUrl,
    'vendorId': vendorId,
    'supplierName': supplierName,
    'supplierCity': supplierCity,
    'supplierLogo': supplierLogo,
    'description': description,
    'dashboardSection': dashboardSection,
    'rating': rating,
    'ratingCount': ratingCount,
    'mrp': mrp,
    'unit': unit,
    'unitVariants': unitVariants.map((variant) => variant.toJson()).toList(),
    'vendorIsOpen': vendorIsOpen,
    'vendorTodayOpenTime': vendorTodayOpenTime,
    'vendorTodayCloseTime': vendorTodayCloseTime,
    'tax': tax,
  };

  static List<ProductUnitVariant> _parseUnitVariants(
    Map<String, dynamic> json,
  ) {
    final parsedVariants = <ProductUnitVariant>[];
    final rawVariants = [json['unitVariants'], json['variants']];

    for (final variants in rawVariants) {
      if (variants is List && variants.isNotEmpty) {
        parsedVariants.addAll(
          variants.whereType<Map<String, dynamic>>().map(
            ProductUnitVariant.fromJson,
          ),
        );
      }
    }

    if (parsedVariants.isNotEmpty) {
      final seen = <String>{};
      return parsedVariants.where((variant) {
        final key = variant.unit.trim().toLowerCase();
        if (key.isEmpty || seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
    }

    final unit = json['unit'] as String? ?? 'item';
    final price = (json['price'] as num? ?? 0).toDouble();
    final discountCost = (json['mrp'] as num? ?? json['cost'] as num? ?? 0)
        .toDouble();
    final stock = (json['stock'] as num? ?? 0).toInt();
    return [
      ProductUnitVariant(
        unit: unit,
        price: price,
        discountCost: discountCost,
        stock: stock,
      ),
    ];
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
