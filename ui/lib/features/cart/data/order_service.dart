import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/order.dart';

class OrderService {
  Future<Order?> placeOrder({
    required String deliveryMethod,
    int? addressId,
    int? deliveryCompanyId,
    String? couponCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse(ApiConstants.orders),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'delivery_method': deliveryMethod,
          if (addressId != null) 'address_id': addressId,
          if (deliveryCompanyId != null) 'delivery_company_id': deliveryCompanyId,
          if (couponCode != null) 'coupon_code': couponCode,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Order.fromJson(data);
      } else {
        String errorMessage = 'Failed to place order';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
        } catch (_) {}
        
        print('CRITICAL: $errorMessage (Status: ${response.statusCode})');
        print('CRITICAL: Response Body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('CRITICAL: Error placing order: $e');
      rethrow;
    }
  }

  Future<List<Order>> getOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConstants.orders),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Order.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching orders: $e');
      return [];
    }
  }
}
