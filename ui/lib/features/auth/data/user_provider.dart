import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class UserProvider extends ChangeNotifier {
  String _id = "";
  String _name = "User";
  String _email = "";
  String? _bio;
  String? _avatar;
  String _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();

  String get id => _id;
  String get name => _name;
  String get email => _email;
  String? get bio => _bio;
  String? get avatar => _avatar;

  UserProvider() {
    loadUserFromPrefs();
  }

  Future<void> loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = json.decode(userDataStr);
        _id = userData['id']?.toString() ?? "";
        _name = userData['name'] ?? "User";
        _email = userData['email'] ?? "";
        _bio = userData['bio'];
        // Prioritize profile_photo_url from backend accessor
        _avatar = userData['profile_photo_url'] ?? userData['avatar_url'] ?? userData['avatar'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading user data in UserProvider: $e");
    }
  }

  void setUser(Map<String, dynamic>? userData) {
    if (userData != null) {
      debugPrint("UserProvider.setUser: profile_photo=${userData['profile_photo']}, url=${userData['profile_photo_url']}");
      _id = userData['id']?.toString() ?? '';
      _name = userData['name'] ?? "User";
      _email = userData['email'] ?? "";
      _bio = userData['bio'];
      // Prioritize profile_photo_url if provided by backend
      _avatar = userData['profile_photo_url'] ?? userData['avatar_url'] ?? userData['avatar']; 
      _cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
      
      _saveUserToPrefs(userData);
      notifyListeners();
    }
  }

  Future<void> _saveUserToPrefs(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
      debugPrint("UserProvider: Saved user data to SharedPreferences");
    } catch (e) {
      debugPrint("Error saving user data in UserProvider: $e");
    }
  }

  // Robust helper to get formatted avatar URL
  String? get avatarUrl {
    if (_avatar == null || _avatar!.isEmpty) return null;
    
    String url;
    // If it's already a full URL, use it
    if (_avatar!.startsWith('http')) {
      url = _avatar!;
    } else {
      // If it's a relative path, prepend the base image URL
      final baseUrl = ApiConstants.baseImageUrl;
      if (baseUrl.endsWith('/') || _avatar!.startsWith('/')) {
        url = '$baseUrl$_avatar';
      } else {
        url = '$baseUrl/$_avatar';
      }
    }

    // Append cache buster to force refresh
    if (url.contains('?')) {
      return '$url&v=$_cacheBuster';
    } else {
      return '$url?v=$_cacheBuster';
    }
  }

  // Helper for stock avatar fallback
  String get effectiveAvatarUrl {
    return avatarUrl ?? "https://i.pravatar.cc/150?u=$_email";
  }
}
