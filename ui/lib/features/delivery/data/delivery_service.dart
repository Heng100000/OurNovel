import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/models/delivery_company.dart';

class DeliveryService {
  // Non-static cache: each instance gets its own, and it's cleared
  // on each hot-restart of the app. Static caches survive state resets
  // and can get "stuck" on empty results after a failed request.
  List<DeliveryCompany>? _cachedCompanies;

  Future<List<DeliveryCompany>> getDeliveryCompanies({bool forceRefresh = false}) async {
    if (_cachedCompanies != null && !forceRefresh) {
      return _cachedCompanies!;
    }

    try {
      final url = ApiConstants.deliveryCompanies;
      print('Fetching delivery companies from: $url');
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        print('Delivery companies JSON: ${response.body}');
        final companies = data.map((json) {
          try {
            return DeliveryCompany.fromJson(json);
          } catch (e) {
            print('Error parsing delivery company: $e, JSON: $json');
            rethrow;
          }
        }).toList();
        _cachedCompanies = companies;
        return companies;
      } else {
        print(
            'Failed to load delivery companies. Status: ${response.statusCode}, Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception fetching delivery companies: $e');
      return [];
    }
  }
}
