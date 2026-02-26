import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class AuthService {
  // Login method
  Future<Map<String, dynamic>> login(String identifier, String password, {String? fcmToken, String? deviceType}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'identifier': identifier,
          'password': password,
          'fcm_token': fcmToken,
          'device_type': deviceType,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['access_token'] == null) {
          return {'success': false, 'message': 'Invalid response from server (No Token)'};
        }
        
        // Save Token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        
        // Save User Data
        if (data['user'] != null) {
             await prefs.setString('user_data', json.encode(data['user']));
        }

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed'
        };
      }
    } on http.ClientException catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Register method
  Future<Map<String, dynamic>> register({
    required String name,
    String? email,
    required String password,
    String? phone,
    String? fcmToken,
    String? deviceType,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.register),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'fcm_token': fcmToken,
          'device_type': deviceType,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 201) {
        // Save Token
        final prefs = await SharedPreferences.getInstance();
        if (data['access_token'] != null) {
          await prefs.setString('token', data['access_token']);
        }
        
        if (data['user'] != null) {
             await prefs.setString('user_data', json.encode(data['user']));
        }

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Logout method
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse(ApiConstants.logout),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      } catch (e) {
        // Prepare for local logout even if API fails
      }
    }

    await prefs.clear();
  }
}
