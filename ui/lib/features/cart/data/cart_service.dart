import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

import 'cart_item_model.dart';

class CartService {
  Future<String?> addToCart(int bookId, {int quantity = 1}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return 'User not authenticated';
      }

      final response = await http
          .post(
            Uri.parse(ApiConstants.cart),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'book_id': bookId,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Failed to add item to cart';
      } else {
        print(
            'Failed to add to cart: ${response.statusCode} - ${response.body}');
        return 'An error occurred while adding to cart';
      }
    } catch (e) {
      print('Error adding to cart: $e');
      return 'Network error occurred';
    }
  }

  Future<List<CartItemModel>> getCartItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConstants.cart),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> itemsJson = data['data'];
          return itemsJson.map((json) => CartItemModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  Future<String?> updateCartItemQuantity(int cartId, int quantity) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return 'User not authenticated';

      final response = await http
          .put(
            Uri.parse('${ApiConstants.cart}/$cartId'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'quantity': quantity}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return null;
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'Failed to update quantity';
      } else {
        return 'An error occurred while updating quantity';
      }
    } catch (e) {
      print('Error updating cart item: $e');
      return 'Network error occurred';
    }
  }

  Future<bool> removeCartItem(int cartId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConstants.cart}/$cartId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error removing cart item: $e');
      return false;
    }
  }
}
