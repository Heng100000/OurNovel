class Order {
  final int id;
  final int userId;
  final int addressId;
  final int deliveryCompanyId;
  final double subtotal;
  final double shippingFee;
  final double totalPrice;
  final String status;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.userId,
    required this.addressId,
    required this.deliveryCompanyId,
    required this.subtotal,
    required this.shippingFee,
    required this.totalPrice,
    required this.status,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      return Order(
        id: int.tryParse(json['id'].toString()) ?? 0,
        userId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
        addressId: int.tryParse(json['address_id']?.toString() ?? '') ?? 0,
        deliveryCompanyId: int.tryParse(json['delivery_company_id']?.toString() ?? '') ?? 0,
        subtotal: double.tryParse(json['subtotal']?.toString() ?? '') ?? 0.0,
        shippingFee: double.tryParse(json['shipping_fee']?.toString() ?? '') ?? 0.0,
        totalPrice: double.tryParse(json['total_price']?.toString() ?? '') ?? 0.0,
        status: json['status']?.toString() ?? 'Pending',
        items: json['items'] != null
            ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
            : null,
      );
    } catch (e) {
      print('DEBUG: Order.fromJson error: $e');
      print('DEBUG: JSON body: $json');
      rethrow;
    }
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int bookId;
  final int quantity;
  final double unitPrice;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.bookId,
    required this.quantity,
    required this.unitPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      return OrderItem(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        orderId: int.tryParse(json['order_id']?.toString() ?? '') ?? 0,
        bookId: int.tryParse(json['book_id']?.toString() ?? '') ?? 0,
        quantity: int.tryParse(json['quantity']?.toString() ?? '') ?? 0,
        unitPrice: double.tryParse(json['unit_price']?.toString() ?? '') ?? 0.0,
      );
    } catch (e) {
      print('DEBUG: OrderItem.fromJson error: $e');
      rethrow;
    }
  }
}
