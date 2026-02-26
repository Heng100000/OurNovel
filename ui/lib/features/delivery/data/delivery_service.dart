import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ui/core/constants/api_constants.dart';
import 'package:ui/core/models/delivery_company.dart';

class DeliveryService {
  final String _baseUrl = ApiConstants.baseUrl;

  Future<List<DeliveryCompany>> getDeliveryCompanies() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/delivery-companies'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => DeliveryCompany.fromJson(json)).toList();
      } else {
        print('Failed to load delivery companies. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching delivery companies: $e');
      return [];
    }
  }
}
