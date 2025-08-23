import 'package:coach_android/config.dart';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state_management/services/state_service.dart';
import 'package:coach_android/models/log_entry.dart';
import 'package:coach_android/services/enhanced_logger.dart';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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

  final wsUrl = AppConfig.webSocketUrl;
  _log.info('Attempting to connect to WebSocket: $wsUrl');
  // Also print directly to ensure visibility
  // ignore: avoid_print
  print('WebSocket: Attempting to connect to: $wsUrl');
  
  EnhancedLogger.info(
    LogSource.webSocket,
    LogCategory.connection,
    'Connecting to WebSocket endpoint',
    {'url': wsUrl},
  );
  
  _channel = IOWebSocketChannel.connect(Uri.parse(wsUrl));
  _log.info('WebSocket connection established.');
  // ignore: avoid_print
  print('WebSocket: Connection established to: $wsUrl');
  
  EnhancedLogger.info(
    LogSource.webSocket,
    LogCategory.connection,
    'WebSocket connection established',
    {'endpoint': wsUrl},
  );
  _reconnectAttempts = 0; // Reset attempts on successful connection

  _channelSubscription = _channel!.stream.listen(
    (message) async {
      _log.fine('Raw WebSocket message received: $message');
      // ignore: avoid_print
      print('WebSocket: Received message: $message');
      
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        _log.info('Parsed WebSocket message: $data');
        
        // Log the WebSocket response with enhanced logger
        EnhancedLogger.info(
          LogSource.webSocket,
          LogCategory.connection,
          'WebSocket message received',
          {
            'type': data['type'] ?? 'status_update',
            'focusing': data['focusing'],
            'num_focuses': data['num_focuses'],
            'focus_time_left': data['focus_time_left'],
          },
        );

        final focusing = data['focusing'] as bool? ?? false;
        final numFocuses = data['num_focuses'] as int? ?? 0;
        final timeLeft = ((data['focus_time_left'] as int? ?? 0) / 60);
        
        // Save the state persistently using StateService
        final stateService = StateService();
        await stateService.saveFocusingState(focusing);
        
        // Send update to UI with all the data
        try {
          service.invoke(
            'updateFocusingState',
            {
              'isFocusing': focusing,
              'focusing': focusing, // For backward compatibility
              'num_focuses': numFocuses,
              'focus_time_left': timeLeft * 60, // Convert back to seconds
            },
          );
        } catch (e) {
          // Ignore MissingPluginException when UI isn't ready
          _log.fine('Could not send update to UI (UI may not be ready): $e');
        }

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
      EnhancedLogger.error(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket connection error',
        {
          'error': error.toString(),
          'endpoint': AppConfig.webSocketUrl,
        },
      );

      closeWebSocket();
      _scheduleReconnect(service);
    },
    onDone: () {
      _log.info('WebSocket connection closed by server.');
      EnhancedLogger.warning(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket connection closed by server',
        {'endpoint': AppConfig.webSocketUrl},
      );
      _scheduleReconnect(service);
    },
    cancelOnError: true,
  );
}

void _scheduleReconnect(
  ServiceInstance service,
) {
  if (_reconnectTimer != null) {
    _log.fine('Reconnection already scheduled.');
    return;
  }

  if (_reconnectAttempts >= _maxReconnectAttempts) {
    _log.severe('Max reconnection attempts reached. Giving up.');
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
    connectWebSocket(service);
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

void requestFocusStatus() {
  // ignore: avoid_print
  print('WebSocket: requestFocusStatus() called');
  
  if (_channel == null) {
    _log.warning('Cannot request focus status - WebSocket not connected');
    // ignore: avoid_print
    print('WebSocket: Cannot request - not connected');
    EnhancedLogger.warning(
      LogSource.webSocket,
      LogCategory.connection,
      'Cannot request focus status - WebSocket not connected',
    );
    return;
  }
  
  try {
    // Send a request to the WebSocket server for current focus status
    final request = {'type': 'status_request'};
    final requestJson = jsonEncode(request);
    
    EnhancedLogger.info(
      LogSource.webSocket,
      LogCategory.connection,
      'Sending focus status request to WebSocket',
      {
        'endpoint': AppConfig.webSocketUrl,
        'request': request,
      },
    );
    
    _channel!.sink.add(requestJson);
    _log.info('Requested focus status from WebSocket: $requestJson');
    // ignore: avoid_print
    print('WebSocket: Sent request to ${AppConfig.webSocketUrl}: $requestJson');
    
  } catch (e) {
    _log.severe('Error requesting focus status: $e');
    EnhancedLogger.error(
      LogSource.webSocket,
      LogCategory.connection,
      'Failed to send focus status request',
      {'error': e.toString()},
    );
  }
}