import 'package:flutter/material.dart';
import '../utils/url_util.dart';

class Book {
  final int id;
  final String title;
  final String? isbn;
  final String? description;
  final String price;
  final String? oldPrice;
  final String? condition;
  int? stockQty;
  int? initialStock;
  final String? status;
  final String? authorName;
  final List<BookImage>? images;
  final Color? color;
  final String? discountedPrice;
  final bool isPopular;
  final bool isNew;
  final double? averageRating;
  final int? reviewCount;
  final int? userRating;
  final int? categoryId;
  final int? authorId;
  final int? pages;
  final String? language;

  Book({
    required this.id,
    required this.title,
    this.isbn,
    this.description,
    required this.price,
    this.oldPrice,
    this.discountedPrice,
    this.condition,
    this.stockQty,
    this.initialStock,
    this.status,
    this.authorName,
    this.images,
    this.color,
    this.isPopular = false,
    this.isNew = false,
    this.averageRating,
    this.reviewCount,
    this.userRating,
    this.categoryId,
    this.authorId,
    this.pages,
    this.language,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final originalPrice = json['price']?.toString() ?? '0';
    final discPrice = json['discounted_price']?.toString();
    
    // Robust ID parsing
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val == null) return 0;
      return int.tryParse(val.toString()) ?? 0;
    }

    int? parseNullableId(dynamic val) {
      if (val is int) return val;
      if (val == null) return null;
      if (val is String && val.isEmpty) return null;
      return int.tryParse(val.toString());
    }

    return Book(
      id: parseId(json['id']),
      title: json['title'] ?? 'Unknown Title',
      isbn: json['isbn']?.toString(),
      description: json['description']?.toString(),
      price: discPrice ?? originalPrice,
      oldPrice: discPrice != null ? originalPrice : json['old_price']?.toString(),
      discountedPrice: discPrice,
      condition: json['condition']?.toString(),
      stockQty: parseNullableId(json['stock_qty']),
      initialStock: parseNullableId(json['stock_qty']),
      status: json['status']?.toString(),
      authorName: json['author']?['name']?.toString(),
      averageRating: json['average_rating'] != null ? double.tryParse(json['average_rating'].toString()) : null,
      reviewCount: parseNullableId(json['review_count']),
      userRating: parseNullableId(json['user_rating']),
      categoryId: parseNullableId(json['category_id'] ?? json['category']?['id']),
      authorId: parseNullableId(json['author_id'] ?? json['author']?['id']),
      pages: parseNullableId(json['pages']),
      language: json['language']?.toString(),
      images: (json['images'] as List?)
              ?.map((i) => BookImage.fromJson(i))
              .toList() ??
          [],
    );
  }

  String get displayImage {
    if (images == null || images!.isEmpty) return '';
    final primary = images!.firstWhere(
      (img) => img.isPrimary, 
      orElse: () => images!.first
    );
    return primary.imageUrl;
  }
}

class BookImage {
  final int? id;
  final String imageUrl;
  final bool isPrimary;

  BookImage({
    this.id,
    required this.imageUrl,
    required this.isPrimary,
  });

  factory BookImage.fromJson(Map<String, dynamic> json) {
    return BookImage(
      id: json['id'] as int?,
      imageUrl: UrlUtil.formatImageUrl(json['image_url']),
      isPrimary: json['is_primary'] == 1 || json['is_primary'] == true,
    );
  }
}
