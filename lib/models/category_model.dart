class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
  });
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}
