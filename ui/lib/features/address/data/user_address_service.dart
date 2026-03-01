import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user_address.dart';

class UserAddressService {
  final String _baseUrl = '${ApiConstants.baseUrl}/user/addresses';

  Future<List<UserAddress>> getAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => UserAddress.fromJson(json)).toList();
      } else {
        print('Failed to load user addresses. Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching user addresses: $e');
      return [];
    }
  }

  Future<UserAddress?> storeAddress(UserAddress address) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(address.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        return UserAddress.fromJson(body['data'] ?? body);
      } else {
        print('Failed to store address. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception storing user address: $e');
      return null;
    }
  }

  Future<UserAddress?> updateAddress(int addressId, UserAddress address) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return null;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$addressId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(address.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);
        return UserAddress.fromJson(body['data'] ?? body);
      } else {
        print('Failed to update address. Status: ${response.statusCode}, Body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception updating user address: $e');
      return null;
    }
  }
}
