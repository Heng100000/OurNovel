import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class ReviewService {
  Future<bool> submitReview({required int bookId, required int rating}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.reviews),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'book_id': bookId,
          'rating': rating,
        }),
      ).timeout(const Duration(seconds: 15));

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error submitting review: $e');
      return false;
    }
  }
}
