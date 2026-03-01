import 'promotion.dart';

class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? bannerImageUrl;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<PromotionModel> promotions;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.bannerImageUrl,
    this.startDate,
    this.endDate,
    required this.isActive,
    required this.promotions,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      bannerImageUrl: json['banner_image_url'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? false,
      promotions: json['promotions'] != null
          ? (json['promotions'] as List)
              .map((p) => PromotionModel.fromJson(p))
              .toList()
          : [],
    );
  }
}
