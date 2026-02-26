import '../utils/url_util.dart';

class Author {
  final int id;
  final String name;
  final String? bio;
  final String? profileImage;

  Author({
    required this.id,
    required this.name,
    this.bio,
    this.profileImage,
  });

  String? get profileImageUrl {
    return UrlUtil.formatImageUrl(profileImage);
  }

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      bio: json['bio'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bio': bio,
      'profile_image': profileImage,
    };
  }
}
