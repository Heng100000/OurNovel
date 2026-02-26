import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/models/author.dart';
import '../../../core/utils/data_cache.dart';

class AuthorService {
  Future<List<Author>> getAllAuthors() async {
    try {
      if (DataCache().hasAuthors && !DataCache().isCacheExpired()) {
        return DataCache().authors!;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.authors),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> authorsJson = data['data'];
          final authors = authorsJson.map((json) => Author.fromJson(json)).toList();
          DataCache().setAuthors(authors);
          return authors;
        }
        return [];
      } else {
        throw Exception('Failed to load authors');
      }
    } catch (e) {
      print('Error fetching authors: $e');
      return [];
    }
  }
}
