import 'package:coach_android/config.dart';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state_management/services/state_service.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; 
import 'dart:async';
import 'dart:convert';

final _log = Logger('WebSocketService');

WebSocketChannel? _channel;
StreamSubscription? _channelSubscription;
Timer? _reconnectTimer;
int _reconnectAttempts = 0;
const int _maxReconnectAttempts = 10;
const Duration _baseReconnectDelay = Duration(seconds: 2);

void connectWebSocket(
  ServiceInstance service,
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
  _reconnectAttempts = 0; // Reset attempts on successful connection

  _channelSubscription = _channel!.stream.listen(
    (message) async {
      _log.fine('Raw WebSocket message received: $message');
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        _log.info('Parsed WebSocket message: $data');

        final focusing = data['focusing'] as bool? ?? false;
        final numFocuses = data['num_focuses'] as int? ?? 0;
        final timeLeft = ((data['focus_time_left'] as int? ?? 0) / 60);
        
        // Save the state persistently using StateService
        final stateService = StateService();
        await stateService.saveFocusingState(focusing);
        
        // Send update to UI with all the data
        service.invoke(
          'updateFocusingState',
          {
            'isFocusing': focusing,
            'focusing': focusing, // For backward compatibility
            'num_focuses': numFocuses,
            'focus_time_left': timeLeft * 60, // Convert back to seconds
          },
        );

        final notificationMessage =
            'Focusing: $focusing. Time left: ${timeLeft.toStringAsFixed(1)}. Focuses: [$numFocuses]';

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
      _scheduleReconnect(service, notificationsPlugin, androidDetails, notificationId);
    },
    onDone: () {
      _log.info('WebSocket connection closed by server.');
      _scheduleReconnect(service, notificationsPlugin, androidDetails, notificationId);
    },
    cancelOnError: true,
  );
}

void _scheduleReconnect(
  ServiceInstance service,
  FlutterLocalNotificationsPlugin notificationsPlugin,
  AndroidNotificationDetails androidDetails,
  int notificationId,
) {
  if (_reconnectTimer != null) {
    _log.fine('Reconnection already scheduled.');
    return;
  }

  if (_reconnectAttempts >= _maxReconnectAttempts) {
    _log.severe('Max reconnection attempts reached. Giving up.');
    notificationsPlugin.show(
      notificationId,
      'Coach',
      'Connection failed after $_maxReconnectAttempts attempts',
      NotificationDetails(android: androidDetails),
    );
    return;
  }

  // Exponential backoff with jitter
  final delay = _baseReconnectDelay * (1 << _reconnectAttempts);
  final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.2).toInt());
  final reconnectDelay = delay + jitter;
  
  _reconnectAttempts++;
  
  _log.info(
    'Scheduling WebSocket reconnection in ${reconnectDelay.inSeconds} seconds (attempt $_reconnectAttempts/$_maxReconnectAttempts).',
  );
  
  _reconnectTimer = Timer(reconnectDelay, () {
    _reconnectTimer = null;
    connectWebSocket(service, notificationsPlugin, androidDetails, notificationId);
  });
}

void closeWebSocket() {
  _channelSubscription?.cancel();
  _channelSubscription = null;
  _channel?.sink.close();
  _channel = null;
  _reconnectTimer?.cancel();
  _reconnectTimer = null;
  _log.info('WebSocket connection closed.');
}

void resetReconnectAttempts() {
  _reconnectAttempts = 0;
}