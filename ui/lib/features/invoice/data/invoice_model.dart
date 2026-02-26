import 'package:flutter/foundation.dart';

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
  final dynamic order;

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

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'],
      orderId: json['order_id'],
      invoiceNo: json['invoice_no'],
      subTotal: json['sub_total'],
      shippingFee: json['shipping_fee'],
      taxAmount: json['tax_amount'],
      grandTotal: json['grand_total'],
      pdfUrl: json['pdf_url'],
      createdAt: DateTime.parse(json['created_at']),
      order: json['order'],
    );
  }
}
