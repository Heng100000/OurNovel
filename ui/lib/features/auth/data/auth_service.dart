import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '838844969174-f2859nav3ruc3jber1an764tikbvfgul.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Google Login method
  Future<Map<String, dynamic>> loginWithGoogle({String? fcmToken, String? deviceType}) async {
    try {
      print('Starting Google Sign-In...');
      
      // Try silent sign-in first for a smoother experience
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // If silent sign-in failed, use the regular interactive sign-in
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
      }
      
      if (googleUser == null) {
        print('Google Sign-In cancelled by user');
        return {'success': false, 'message': 'Google Sign-In cancelled'};
      }

      print('Google User: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print('ID Token available: ${idToken != null}');
      print('Access Token available: ${accessToken != null}');

      if (idToken == null) {
        return {'success': false, 'message': 'Failed to get ID Token from Google. Please ensure you have added your SHA-1 fingerprint to Firebase and the Google Cloud Console.'};
      }

      final response = await http.post(
        Uri.parse(ApiConstants.googleLogin),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'idToken': idToken,
          'fcm_token': fcmToken,
          'device_type': deviceType,
        }),
      ).timeout(const Duration(seconds: 15));

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']);
        
        if (data['user'] != null) {
          await prefs.setString('user_data', json.encode(data['user']));
        }

        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google Login failed'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Facebook Login method
  Future<Map<String, dynamic>> loginWithFacebook({String? fcmToken, String? deviceType}) async {
    try {
      print('Starting Facebook Sign-In...');
      
      // Force logout first to ensure the user is prompted for credentials/flow
      await FacebookAuth.instance.logOut();
      
      // Attempt login with webOnly behavior to force account selector/login screen
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['public_profile', 'email'],
        loginBehavior: LoginBehavior.webOnly,
      );

      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;
        
        if (accessToken == null) {
          return {'success': false, 'message': 'Failed to get Access Token from Facebook'};
        }

        print('Facebook Login Success. Token available');

        final response = await http.post(
          Uri.parse(ApiConstants.facebookLogin),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'accessToken': accessToken.tokenString,
            'fcm_token': fcmToken,
            'device_type': deviceType,
          }),
        ).timeout(const Duration(seconds: 15));

        final data = json.decode(response.body);

        if (response.statusCode == 200) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', data['access_token']);
          
          if (data['user'] != null) {
            await prefs.setString('user_data', json.encode(data['user']));
          }

          return {'success': true, 'data': data};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Facebook Login failed'
          };
        }
      } else if (result.status == LoginStatus.cancelled) {
        print('Facebook Sign-In cancelled by user');
        return {'success': false, 'message': 'Facebook Sign-In cancelled'};
      } else {
        print('Facebook Sign-In failed: ${result.message}');
        return {'success': false, 'message': 'Facebook Sign-In failed: ${result.message}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

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

    try {
      // Sign out from Google
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error during Google sign out: $e');
    }

    try {
      // Sign out from Facebook
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('Error during Facebook sign out: $e');
    }

    await prefs.clear();
  }

  // Update Profile method
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? bio,
    File? avatar,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        return {'success': false, 'message': 'Not logged in'};
      }

      final uri = Uri.parse(ApiConstants.userProfile);
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['name'] = name;
      request.fields['email'] = email;
      if (bio != null) {
        request.fields['bio'] = bio;
      }

      if (avatar != null) {
        debugPrint("Attaching avatar file: ${avatar.path}");
        request.files.add(await http.MultipartFile.fromPath(
          'avatar',
          avatar.path,
        ));
      }

      debugPrint("Sending request to: ${request.url}");
      debugPrint("Request fields: ${request.fields}");
      debugPrint("Request files: ${request.files.length}");

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Profile Status: ${response.statusCode}');
      print('Update Profile Response: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['user'] != null) {
          await prefs.setString('user_data', json.encode(data['user']));
        }
        return {'success': true, 'user': data['user'], 'data': data};
      } else {
        return {
          'success': false, 
          'message': data['message'] ?? 'Failed to update profile',
          'errors': data['errors']
        };
      }
    } catch (e) {
      print('Update Profile error: $e');
      return {'success': false, 'message': 'An error occurred during profile update'};
    }
  }
}
