class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    required this.mediaUrl,
    this.video = false,
  });
  final String id;
  final String title;
  final String mediaUrl;
  final bool video;
}
