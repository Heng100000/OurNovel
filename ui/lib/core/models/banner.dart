import '../utils/url_util.dart';

class BannerModel {
  final int id;
  final String title;
  final String imageUrl;
  final String? actionType;
  final String? actionId;
  final String? actionUrl;
  final int displayOrder;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.actionType,
    this.actionId,
    this.actionUrl,
    required this.displayOrder,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      imageUrl: UrlUtil.formatImageUrl(json['image_url'] ?? ''),
      actionType: json['action_type'],
      actionId: json['action_id']?.toString(),
      actionUrl: json['action_url'],
      displayOrder: json['display_order'] is int 
          ? json['display_order'] 
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }
}
