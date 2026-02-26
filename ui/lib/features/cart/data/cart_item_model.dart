import '../../../core/utils/url_util.dart';

class CartItemModel {
  final int id;
  final int userId;
  final int bookId;
  final String? bookTitle;
  final String? bookImage;
  int quantity;
  final double unitPrice;
  final double itemTotal;

  CartItemModel({
    required this.id,
    required this.userId,
    required this.bookId,
    this.bookTitle,
    this.bookImage,
    required this.quantity,
    required this.unitPrice,
    required this.itemTotal,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      bookTitle: json['book_title'],
      bookImage: UrlUtil.formatImageUrl(json['book_image']),
      quantity: json['quantity'] ?? 1,
      unitPrice: double.tryParse(json['unit_price'].toString()) ?? 0.0,
      itemTotal: double.tryParse(json['item_total'].toString()) ?? 0.0,
    );
  }
}
