import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/book.dart';

class WishlistService {
  Future<List<Book>> getWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse(ApiConstants.wishlist),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> itemsJson = data['data'] ?? [];
        // Backend returns wishlist items which contain 'book' object
        return itemsJson.map((item) => Book.fromJson(item['book'])).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching wishlist: $e');
      return [];
    }
  }

  Future<bool> addToWishlist(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.post(
        Uri.parse(ApiConstants.wishlist),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'book_id': bookId}),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error adding to wishlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWishlist(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('${ApiConstants.wishlist}/$bookId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('Error removing from wishlist: $e');
      return false;
    }
  }
}
