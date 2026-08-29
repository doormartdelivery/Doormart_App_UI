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
    this.mrp = 0,
    this.unit = 'item',
    this.unitVariants = const [],
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
  final double mrp;
  final String unit;
  final List<ProductUnitVariant> unitVariants;

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
      mrp: (json['mrp'] as num? ?? 0).toDouble(),
      unit: json['unit'] as String? ?? 'item',
      unitVariants: _parseUnitVariants(json),
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
    'mrp': mrp,
    'unit': unit,
    'unitVariants': unitVariants.map((variant) => variant.toJson()).toList(),
  };

  static List<ProductUnitVariant> _parseUnitVariants(
    Map<String, dynamic> json,
  ) {
    final variants = json['unitVariants'];
    if (variants is List && variants.isNotEmpty) {
      return variants
          .whereType<Map<String, dynamic>>()
          .map(ProductUnitVariant.fromJson)
          .toList();
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
