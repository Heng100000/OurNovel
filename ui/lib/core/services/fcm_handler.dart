import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../features/notifications/data/notification_provider.dart';

class FcmHandler {
  // Global stream for book updates
  static final StreamController<void> _bookUpdateController =
      StreamController<void>.broadcast();
  static Stream<void> get onBookUpdate => _bookUpdateController.stream;

  static Future<void> initialize(BuildContext context) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions for iOS
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Subscribe to a global topic for book updates
    await messaging.subscribeToTopic('books_update');

    // Foreground Listeners
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
          'FCM Message received in foreground: ${message.notification?.title}');

      // Handle silent data-only messages for app state updates
      if (message.data['type'] == 'book_updated') {
        debugPrint('FCM: Received book_updated silent push. Emitting event.');
        _bookUpdateController.add(null);
      }

      // If it has a notification payload, it's a standard push (like an order update or admin message)
      if (message.notification != null) {
        // Play default notification sound
        FlutterRingtonePlayer().playNotification();

        // Sync notification data with backend
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            Provider.of<NotificationProvider>(context, listen: false)
                .fetchUnreadCount();
          }
        });
      }
    });

    // Handle interaction when app is in background but opened via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Message opened app: ${message.notification?.title}');
      if (context.mounted) {
        Navigator.pushNamed(context, '/notifications');
      }
    });
  }
}
