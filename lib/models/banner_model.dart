import '../core/utils/network_image_url.dart';

class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.logoUrl = '',
    this.active = true,
  });
  final String id;
  final String title;
  final String imageUrl;
  final String logoUrl;
  final bool active;

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['_id'] as String? ?? json['id'] as String,
      title: json['title'] as String? ?? '',
      imageUrl: NetworkImageUrl.normalize(json['imageUrl'] as String?),
      logoUrl: NetworkImageUrl.normalize(json['logoUrl'] as String?),
      active: json['active'] as bool? ?? true,
    );
  }
}
