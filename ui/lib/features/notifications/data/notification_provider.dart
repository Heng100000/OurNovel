import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  List<dynamic> _notifications = [];
  List<dynamic> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void incrementCount() {
    _unreadCount++;
    notifyListeners();
  }

  void resetCount() {
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> fetchUnreadCount() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.notifications),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _notifications = data['data'];
          _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    // Optimistic update
    final index = _notifications.indexWhere((n) => n['id'] == notificationId);
    if (index != -1) {
      _notifications[index]['is_read'] = true;
      _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
      notifyListeners();
    }

    try {
      final response = await http.patch(
        Uri.parse('${ApiConstants.notifications}/$notificationId/read'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Optional: Revert on failure
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    // Optimistic update
    for (var n in _notifications) {
      n['is_read'] = true;
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.notifications}/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Handle failure
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    // Optimistically remove from local list
    _notifications.removeWhere((n) => n['id'] == notificationId);
    _unreadCount = _notifications.where((n) => n['is_read'] == false).length;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.notifications}/$notificationId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Handle failure
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    // Optimistically clear local list
    _notifications.clear();
    _unreadCount = 0;
    notifyListeners();

    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.notifications}/delete-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Handle failure
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }
}
