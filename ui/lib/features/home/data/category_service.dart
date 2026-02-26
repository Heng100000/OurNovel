import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/models/category.dart';
import '../../../core/utils/data_cache.dart';

class CategoryService {
  Future<List<Category>> getAllCategories() async {
    try {
      if (DataCache().hasCategories && !DataCache().isCacheExpired()) {
        return DataCache().categories!;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.categories),
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final List<dynamic> categoriesJson = data['data'];
          final categories = categoriesJson.map((json) => Category.fromJson(json)).toList();
          DataCache().setCategories(categories);
          return categories;
        }
        return [];
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
