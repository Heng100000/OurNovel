import '../utils/url_util.dart';

class BannerModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? description;
  final String imageUrl;
  final int? discountPercentage;
  final String? buttonText;
  final String? actionType;
  final String? actionId;
  final String? actionUrl;
  final int displayOrder;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.imageUrl,
    this.discountPercentage,
    this.buttonText,
    this.actionType,
    this.actionId,
    this.actionUrl,
    required this.displayOrder,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      subtitle: json['subtitle'],
      description: json['description'],
      imageUrl: UrlUtil.formatImageUrl(json['image_url'] ?? ''),
      discountPercentage: json['discount_percentage'] is int
          ? json['discount_percentage']
          : int.tryParse(json['discount_percentage']?.toString() ?? ''),
      buttonText: json['button_text'],
      actionType: json['action_type'],
      actionId: json['action_id']?.toString(),
      actionUrl: json['action_url'],
      displayOrder: json['display_order'] is int
          ? json['display_order']
          : int.tryParse(json['display_order']?.toString() ?? '0') ?? 0,
    );
  }
}
