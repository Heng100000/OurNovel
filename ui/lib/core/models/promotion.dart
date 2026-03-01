import 'book.dart';

class PromotionModel {
  final int id;
  final int? eventId;
  final String eventName;
  final String discountType;
  final double discountValue;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final List<Book> books;

  PromotionModel({
    required this.id,
    this.eventId,
    required this.eventName,
    required this.discountType,
    required this.discountValue,
    this.startDate,
    this.endDate,
    required this.status,
    required this.books,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    return PromotionModel(
      id: json['id'],
      eventId: json['event_id'],
      eventName: json['event_name'],
      discountType: json['discount_type'],
      discountValue: double.tryParse(json['discount_value'].toString()) ?? 0.0,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'].replaceAll('Z', '')) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'].replaceAll('Z', '')) : null,
      status: json['status'],
      books: json['books'] != null
          ? (json['books'] as List)
              .map((b) => Book.fromJson(b))
              .toList()
          : [],
    );
  }
}
