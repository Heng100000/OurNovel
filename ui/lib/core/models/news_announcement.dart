import '../utils/url_util.dart';

class NewsAnnouncement {
  final int id;
  final String title;
  final String? typeNews;
  final String? imageUrl;
  final String description;
  final DateTime? createdAt;

  NewsAnnouncement({
    required this.id,
    required this.title,
    this.typeNews,
    this.imageUrl,
    required this.description,
    this.createdAt,
  });

  factory NewsAnnouncement.fromJson(Map<String, dynamic> json) {
    return NewsAnnouncement(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'] ?? '',
      typeNews: json['type_news'],
      imageUrl: json['image_url'] != null ? UrlUtil.formatImageUrl(json['image_url']) : null,
      description: json['description'] ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
    );
  }
}
