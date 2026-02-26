import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/book.dart';
import '../../../core/utils/data_cache.dart';

class BookService {
  Future<List<Book>> getBooks({String? condition}) async {
    try {
      String url = ApiConstants.books;
      if (condition != null) {
        url += '?condition=$condition';
      }

      if (condition == null && DataCache().hasAllBooks && !DataCache().isCacheExpired()) {
        return DataCache().allBooks!;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final headers = {
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> booksJson = data['data'];
          final books = booksJson.map((json) => Book.fromJson(json)).toList();
          if (condition == null) {
            DataCache().setAllBooks(books);
          }
          return books;
        }
        return [];
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      print('Error fetching books: $e');
      return [];
    }
  }

  Future<List<Book>> getNewBooks() async {
    return getBooks(condition: 'New');
  }

  Future<List<Book>> getPopularBooks() async {
    return getBooks(condition: 'Popular');
  }

  Future<Book?> getBookById(int id) async {
    try {
      final String url = '${ApiConstants.books}/$id';
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      final headers = {
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return Book.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching book by ID: $e');
      return null;
    }
  }
}
