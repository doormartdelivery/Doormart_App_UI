import '../core/utils/network_image_url.dart';

class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.cost,
    required this.stock,
    required this.imageUrl,
    this.rating = 4.5,
    this.unit = 'item',
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final double cost;
  final int stock;
  final String imageUrl;
  final double rating;
  final String unit;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final stockQuantity = (json['stockQuantity'] as num?)?.toInt();
    final stock = (json['stock'] as num?)?.toInt();
    final stockValue = (stockQuantity != null && stockQuantity > 0)
        ? stockQuantity
        : (stock != null ? stock : (stockQuantity ?? 0));
    return ProductModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      price: (json['price'] as num).toDouble(),
      cost: (json['cost'] as num? ?? 0).toDouble(),
      stock: (stockValue as num).toInt(),
      imageUrl: NetworkImageUrl.normalize(json['imageUrl'] as String?),
      rating: (json['rating'] as num? ?? 4.5).toDouble(),
      unit: json['unit'] as String? ?? 'item',
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
    'rating': rating,
    'unit': unit,
  };
}
