import 'package:coach_android/config.dart';
import 'package:coach_android/persistent_log.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

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
      _log.info('WebSocket message received: $message');
      notificationsPlugin.show(
        notificationId,
        'Coach',
        message.toString(),
        NotificationDetails(android: androidDetails),
      );
      PersistentLog.addLog(message.toString());
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
    return; // Already scheduled
  }
  const reconnectDelay = Duration(seconds: 5);
  _log.info(
    'Scheduling WebSocket reconnection in ${reconnectDelay.inSeconds} seconds.',
  );
  _reconnectTimer = Timer(reconnectDelay, () {
    _reconnectTimer = null; // Clear the timer
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
