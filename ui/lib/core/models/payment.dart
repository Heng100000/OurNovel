import '../utils/url_util.dart';

class Payment {
  final int id;
  final int orderId;
  final String method;
  final double amount;
  final String status;
  final String? txnId;
  final String? qrImageUrl;
  final String? qrCode;
  final String? deepLink;
  final DateTime? createdAt;

  Payment({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    this.txnId,
    this.qrImageUrl,
    this.qrCode,
    this.deepLink,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      orderId: json['order_id'],
      method: json['method'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'],
      txnId: json['txn_id'],
      qrImageUrl: UrlUtil.formatImageUrl(json['qr_image_url']),
      qrCode: json['qr_code'],
      deepLink: json['deep_link'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }
}
