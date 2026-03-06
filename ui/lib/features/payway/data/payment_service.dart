import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/payment.dart';

class PaymentService {
  Future<Payment?> createPayment({
    required int orderId,
    required String method,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiConstants.payments),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'order_id': orderId,
          'method': method,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        // Resource returns data wrapped in 'data' key usually, check backend
        final paymentData = data['data'] ?? data;
        return Payment.fromJson(paymentData);
      } else {
        String errorMessage = 'Failed to create payment';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}
        
        print('CRITICAL: $errorMessage (Status: ${response.statusCode})');
        print('CRITICAL: Response Body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('CRITICAL: Error creating payment: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkKhqrStatus(int paymentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return {'paid': false, 'status': 'error'};

      final response = await http.get(
        Uri.parse('${ApiConstants.payments}/$paymentId/check-khqr'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'paid': false, 'status': 'pending'};
    } catch (e) {
      print('Error checking KHQR status: $e');
      return {'paid': false, 'status': 'error'};
    }
  }
}
