import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import 'invoice_model.dart';

class InvoiceService {
  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        // Assuming ApiConstants.invoices exists, I should check or just hardcode for now
        Uri.parse('${ApiConstants.baseUrl}/invoices'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'] ?? [];
        return invoicesData.map((json) => InvoiceModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load invoices');
      }
    } catch (e) {
      throw Exception('Error loading invoices: $e');
    }
  }
}
