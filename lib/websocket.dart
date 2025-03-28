import 'package:coach_android/config.dart';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state.dart'; // Import AppState
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'dart:convert';

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
    (message) async { // Add async keyword here
      _log.fine('Raw WebSocket message received: $message');
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        _log.info('Parsed WebSocket message: $data');

        final focusing = data['focusing'] as bool? ?? false;
        await AppState.saveFocusingState(focusing); 

        final numFocuses = data['num_focuses'] as int? ?? 0;
        final timeLeft = (data['focus_time_left'] as int? ?? 0) / 60;
        final notificationMessage =
            'Focusing: $focusing. Time left: $timeLeft. Focuses: [$numFocuses]';

        notificationsPlugin.show(
          notificationId,
          'Coach',
          notificationMessage,
          NotificationDetails(android: androidDetails),
        );
        PersistentLog.addLog(message);
      } catch (e) {
        _log.severe('Error processing WebSocket message: $e');
        _log.severe('Original message: $message');
        PersistentLog.addLog(
          'Error processing WebSocket message. Original message: $message',
        );
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
