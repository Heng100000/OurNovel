import 'package:flutter/foundation.dart';
import '../../../../core/constants/api_constants.dart';

class InvoiceModel {
  final int id;
  final int orderId;
  final String invoiceNo;
  final String subTotal;
  final String shippingFee;
  final String taxAmount;
  final String grandTotal;
  final String? pdfUrl;
  final DateTime createdAt;
  final Map<String, dynamic>? order;

  InvoiceModel({
    required this.id,
    required this.orderId,
    required this.invoiceNo,
    required this.subTotal,
    required this.shippingFee,
    required this.taxAmount,
    required this.grandTotal,
    this.pdfUrl,
    required this.createdAt,
    this.order,
  });

  // ── Convenience accessors for order nested data ──────────────────────────────

  Map<String, dynamic> get orderData => order ?? {};
  Map<String, dynamic> get user => (orderData['user'] as Map<String, dynamic>?) ?? {};
  Map<String, dynamic> get address => (orderData['address'] as Map<String, dynamic>?) ?? {};
  List<dynamic> get orderItems => (orderData['order_items'] as List<dynamic>?) ?? [];
  Map<String, dynamic>? get deliveryCompany => orderData['delivery_company'] as Map<String, dynamic>?;
  Map<String, dynamic>? get payment => orderData['payment'] as Map<String, dynamic>?;

  String? get deliveryLogoUrl {
    final path = deliveryCompany?['logo_path'] as String?;
    if (path == null || path.isEmpty) return null;
    return '${ApiConstants.baseImageUrl}/$path';
  }
  String get customerName => user['name'] as String? ?? 'Guest';
  String get customerEmail => user['email'] as String? ?? '';
  String get customerPhone => user['phone'] as String? ?? 'N/A';
  String get addressDetails => address['address_details'] as String? ?? '';
  String get addressCity => address['city'] as String? ?? '';
  String get orderStatus => orderData['status'] as String? ?? '';
  String? get paymentMethod => payment?['method'] as String?;
  String? get paymentStatus => payment?['status'] as String?;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      orderId: json['order_id'],
      invoiceNo: json['invoice_no'],
      subTotal: (json['sub_total'] ?? '0').toString(),
      shippingFee: (json['shipping_fee'] ?? '0').toString(),
      taxAmount: (json['tax_amount'] ?? '0').toString(),
      grandTotal: (json['grand_total'] ?? '0').toString(),
      pdfUrl: json['pdf_url'],
      createdAt: DateTime.parse(json['created_at']),
      order: json['order'] as Map<String, dynamic>?,
    );
  }
}
