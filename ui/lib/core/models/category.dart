import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final int? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  IconData get icon {
    final String nameLower = name.toLowerCase();
    if (nameLower.contains('horror')) return Icons.psychology_outlined;
    if (nameLower.contains('romance')) return Icons.favorite_border;
    if (nameLower.contains('history')) return Icons.history_edu;
    if (nameLower.contains('thriller')) return Icons.theater_comedy_outlined;
    if (nameLower.contains('adventure')) return Icons.landscape_outlined;
    if (nameLower.contains('suspense')) return Icons.help_outline;
    if (nameLower.contains('graphic') || nameLower.contains('comic')) return Icons.auto_stories_outlined;
    if (nameLower.contains('women')) return Icons.face_3_outlined;
    if (nameLower.contains('detective') || nameLower.contains('mystery')) return Icons.search;
    if (nameLower.contains('fiction')) return Icons.auto_stories;
    if (nameLower.contains('science')) return Icons.science_outlined;
    if (nameLower.contains('fantasy')) return Icons.auto_awesome_outlined;
    if (nameLower.contains('education') || nameLower.contains('learning')) return Icons.school_outlined;
    if (nameLower.contains('art')) return Icons.palette_outlined;
    if (nameLower.contains('business')) return Icons.business_center_outlined;
    if (nameLower.contains('cook') || nameLower.contains('food')) return Icons.restaurant_outlined;
    
    return Icons.bookmark_outline; // Default icon
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'],
      parentId: json['parent_id'] != null 
          ? (json['parent_id'] is int ? json['parent_id'] : int.tryParse(json['parent_id'].toString())) 
          : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
