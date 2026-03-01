import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:ui/core/constants/api_constants.dart';

class RealtimeService extends ChangeNotifier {
  static final RealtimeService _instance = RealtimeService._internal();

  factory RealtimeService() {
    return _instance;
  }

  RealtimeService._internal();

  WebSocketChannel? _channel;
  bool isConnected = false;

  Future<void> init() async {
    if (isConnected) return;

    try {
      // Connect specifically to Reverb instance using centralized constants
      final wsUrl = Uri.parse(ApiConstants.wsUrl);
      _channel = WebSocketChannel.connect(wsUrl);

      _channel!.stream.listen(
        (message) {
          // if (kDebugMode) print("RealtimeService Message: $message");
          try {
            final data = jsonDecode(message);
            final eventName = data['event'];
            final channelName = data['channel'];

            if (eventName == 'pusher:connection_established') {
              isConnected = true;
              if (kDebugMode) print("RealtimeService Connected via standard WebSockets!");
              
              // Subscribe to public channel
              _channel!.sink.add(jsonEncode({
                "event": "pusher:subscribe",
                "data": {"channel": "public-updates"}
              }));
            } else if (channelName == 'public-updates' && eventName == 'realtime.update') {
              if (kDebugMode) print("RealtimeService received update signal!");
              notifyListeners();
            }
          } catch (e) {
            if (kDebugMode) {
              print("RealtimeService parse error: $e");
            }
          }
        },
        onError: (error) {
          if (kDebugMode) {
            print("RealtimeService Error: $error");
          }
          isConnected = false;
        },
        onDone: () {
          if (kDebugMode) {
            print("RealtimeService Disconnected");
          }
          isConnected = false;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print("RealtimeService Init ERROR: $e");
      }
    }
  }

  void disposeService() {
    _channel?.sink.close();
    isConnected = false;
  }
}

