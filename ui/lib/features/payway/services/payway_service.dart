import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';

class PayWayService {
  Future<Map<String, dynamic>> generateQr(double amount, String billNumber, String mobileNumber) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/Payway/generate');
      
      debugPrint('Calling PayWay Generate: $url');
      debugPrint('Body: ${jsonEncode({
          'amount': amount,
          'billNumber': billNumber,
          'mobileNumber': mobileNumber,
        })}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'amount': amount,
          'billNumber': billNumber,
          'mobileNumber': mobileNumber,
        }),
      );

      debugPrint('PayWay Response Status: ${response.statusCode}');
      debugPrint('PayWay Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate QR: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating QR: $e');
    }
  }

  Future<Map<String, dynamic>> checkTransaction(String md5, double amount) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/Payway/check-by-md5/$md5?expectedAmount=$amount');
      
      debugPrint('Checking PayWay Transaction: $url');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to check transaction: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error checking transaction: $e');
    }
  }
}
