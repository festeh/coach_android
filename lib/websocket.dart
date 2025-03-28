import 'package:coach_android/config.dart';
import 'package:coach_android/persistent_log.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:convert'; // Import dart:convert for jsonDecode

final _log = Logger('WebSocketService');

WebSocketChannel? _channel;
StreamSubscription? _channelSubscription;
Timer? _reconnectTimer;

void connectWebSocket(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  AndroidNotificationDetails androidDetails,
  int notificationId,
) {
  if (_channel != null || _reconnectTimer != null) {
    _log.fine(
      'Skipping connection attempt (already connected or reconnect scheduled).',
    );
    return;
  }

  if (AppConfig.webSocketUrl.isEmpty) {
    _log.warning('WebSocket URL not available. Cannot connect.');
    return;
  }

  _log.info('Attempting to connect to WebSocket: ${AppConfig.webSocketUrl}');
  _channel = IOWebSocketChannel.connect(Uri.parse(AppConfig.webSocketUrl));
  _log.info('WebSocket connection established.');

  _channelSubscription = _channel!.stream.listen(
    (message) {
      _log.fine('Raw WebSocket message received: $message');
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        _log.info('Parsed WebSocket message: $data');

        // Example: Extract 'type' field
        final messageType = data['type'] as String? ?? 'Unknown Type';
        final notificationMessage = 'Received update: $messageType'; // Customize as needed

        notificationsPlugin.show(
          notificationId,
          'Coach',
          notificationMessage,
          NotificationDetails(android: androidDetails),
        );
        // Log the parsed data or a summary
        PersistentLog.addLog('Received WebSocket data: $messageType'); // Log type or full data map
      } on FormatException catch (e) {
        _log.severe('Failed to parse WebSocket message as JSON: $e');
        _log.severe('Original message: $message');
        // Optionally show an error notification or log differently
        PersistentLog.addLog('Error parsing WebSocket message.');
      } catch (e) {
        _log.severe('Error processing WebSocket message: $e');
        PersistentLog.addLog('Error processing WebSocket message.');
      }
    },
    onError: (error) {
      _log.severe('WebSocket error: $error');

      notificationsPlugin.show(
        notificationId,
        'Coach',
        'Connection Error',
        NotificationDetails(android: androidDetails),
      );
      closeWebSocket();
      _scheduleReconnect(notificationsPlugin, androidDetails, notificationId);
    },
    onDone: () {
      _log.info('WebSocket connection closed by server.');
      _scheduleReconnect(notificationsPlugin, androidDetails, notificationId);
    },
    cancelOnError: true,
  );
}

void _scheduleReconnect(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  AndroidNotificationDetails androidDetails,
  int notificationId,
) {
  if (_reconnectTimer != null) {
    _log.fine('Reconnection already scheduled.');
    return;
  }
  const reconnectDelay = Duration(seconds: 5);
  _log.info(
    'Scheduling WebSocket reconnection in ${reconnectDelay.inSeconds} seconds.',
  );
  _reconnectTimer = Timer(reconnectDelay, () {
    _reconnectTimer = null;
    connectWebSocket(notificationsPlugin, androidDetails, notificationId);
  });
}

void closeWebSocket() {
  _channelSubscription?.cancel();
  _channel?.sink.close();
  _reconnectTimer?.cancel();
  _reconnectTimer = null;
  _channelSubscription?.cancel();
  _channelSubscription = null;
  _channel?.sink.close();
  _channel = null;
  _log.info('WebSocket connection closed.');
}
