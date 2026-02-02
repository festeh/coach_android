import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';

final _log = Logger('WebSocketService');

class WebSocketService {
  static final _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _focusQueryTimer;

  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _focusQueryInterval = Duration(seconds: 60);

  Completer<Map<String, dynamic>>? _pendingRequest;

  // Stream for focus updates that can be listened to directly
  final _focusUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get focusUpdates =>
      _focusUpdatesController.stream;

  bool get isConnected => _isConnected;

  /// Get detailed connection status for debugging
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'reconnectAttempts': _reconnectAttempts,
      'hasPendingRequest': _pendingRequest != null,
      'hasChannel': _channel != null,
      'hasSubscription': _subscription != null,
      'hasFocusQueryTimer': _focusQueryTimer != null,
      'websocketUrl': AppConfig.webSocketUrl,
    };
  }

  /// Initialize and connect to WebSocket server
  Future<void> initialize() async {
    if (AppConfig.webSocketUrl.isEmpty) {
      _log.warning('WebSocket URL not configured');
      return;
    }

    _log.info('Initializing WebSocket service');
    await _connect();
  }

  /// Connect to WebSocket server
  Future<void> _connect() async {
    if (_isConnecting || _isConnected) {
      _log.fine('Already connected or connecting');
      return;
    }

    _isConnecting = true;

    try {
      _log.info('Connecting to WebSocket: ${AppConfig.webSocketUrl}');

      _channel = IOWebSocketChannel.connect(
        Uri.parse(AppConfig.webSocketUrl),
        connectTimeout: const Duration(seconds: 10),
      );

      await _channel!.ready;

      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      _startPeriodicFocusQuery();

      _log.info('WebSocket connected successfully');
    } catch (e) {
      _isConnecting = false;
      _handleError(e);
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      _log.fine('Received WebSocket message: $message');

      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final messageType = data['type'] as String?;

      // Handle response to pending requests
      // Map server response types to our request types

      if (_pendingRequest != null) {
        final completer = _pendingRequest;
        _pendingRequest = null;
        completer?.complete(data);
        return;
      }

      // Emit focus updates to dedicated stream
      if (messageType == 'focusing' ||
          messageType == 'focusing_status' ||
          (messageType == null && data.containsKey('focusing'))) {
        _focusUpdatesController.add(data);
        _log.fine('Focus update emitted to stream: focusing=${data['focusing']}');
      }

    } catch (e) {
      _log.severe('Error processing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _log.severe('WebSocket error: $error');

    _cleanup();
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    _log.info('WebSocket disconnected');

    _cleanup();
    _scheduleReconnect();
  }

  /// Clean up connection resources
  void _cleanup() {
    _isConnected = false;
    _isConnecting = false;

    _subscription?.cancel();
    _subscription = null;

    _channel?.sink.close();
    _channel = null;

    _focusQueryTimer?.cancel();
    _focusQueryTimer = null;

    // Complete any pending request with error
    if (_pendingRequest != null && !_pendingRequest!.isCompleted) {
      _pendingRequest!.completeError(Exception('WebSocket connection lost'));
      _pendingRequest = null;
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log.severe('Max reconnection attempts reached ($_reconnectAttempts). Giving up.');
      return;
    }

    _reconnectAttempts++;

    // Exponential backoff with jitter
    final delay = Duration(
      milliseconds:
          _baseReconnectDelay.inMilliseconds *
              pow(2, min(_reconnectAttempts - 1, 6)).toInt() +
          Random().nextInt(1000),
    );

    _log.info(
      'Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s',
    );

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }

  /// Start periodic focus query timer to get updated focus data
  void _startPeriodicFocusQuery() {
    _focusQueryTimer?.cancel();
    _focusQueryTimer = Timer.periodic(_focusQueryInterval, (_) async {
      if (_isConnected) {
        try {
          _log.fine('Sending periodic focus query');
          await requestFocusStatus();
        } catch (e) {
          _log.warning('Periodic focus query failed: $e');
          // Continue running, don't cancel the timer for temporary failures
        }
      }
    });
  }

  /// Send a message through WebSocket
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (!_isConnected || _channel == null) {
      throw Exception('WebSocket not connected');
    }

    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);

      _log.fine('Sent WebSocket message: $jsonMessage');
    } catch (e) {
      _log.severe('Failed to send WebSocket message: $e');
      throw Exception('Failed to send WebSocket message: $e');
    }
  }

  /// Send focus command to WebSocket server
  Future<void> sendFocusCommand() async {
    _log.info('Sending focus command to WebSocket server');
    
    if (!_isConnected) {
      throw Exception('WebSocket not connected');
    }
    
    try {
      await _sendMessage({'type': 'focus'});
      _log.info('Focus command sent successfully');
    } catch (e) {
      _log.severe('Failed to send focus command: $e');
      
      rethrow;
    }
  }

  /// Request focus status from WebSocket server
  /// This is the abstracted method that handles connection management
  Future<Map<String, dynamic>> requestFocusStatus() async {
    _log.info(
      'Requesting focus status from WebSocket - Connection state: $_isConnected',
    );

    // Check if connected, if not try to connect
    if (!_isConnected) {
      _log.info('WebSocket not connected, attempting to connect first');

      try {
        await _connect();

        // Wait a bit for connection to establish with exponential backoff
        const maxWaitTime = Duration(seconds: 8);
        const checkInterval = Duration(milliseconds: 200);
        var totalWaitTime = Duration.zero;

        while (!_isConnected && totalWaitTime < maxWaitTime) {
          await Future.delayed(checkInterval);
          totalWaitTime += checkInterval;
          _log.fine(
            'Waiting for connection... ${totalWaitTime.inMilliseconds}ms elapsed',
          );
        }

        if (!_isConnected) {
          final errorMsg =
              'Could not establish WebSocket connection after ${totalWaitTime.inSeconds}s. URL: ${AppConfig.webSocketUrl}';
          _log.severe(errorMsg);
          throw Exception(errorMsg);
        }
        _log.info(
          'WebSocket connection established successfully for focus status request',
        );
        
        // Start periodic focus queries if not already running
        if (_focusQueryTimer == null || !_focusQueryTimer!.isActive) {
          _startPeriodicFocusQuery();
        }
      } catch (e) {
        _log.severe('Failed to establish WebSocket connection: $e');
        throw Exception('WebSocket connection failed: $e');
      }
    } else {
      _log.info(
        'WebSocket already connected, proceeding with focus status request',
      );
    }

    // Create a completer for this request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequest = completer;

    try {
      // Send the request
      await _sendMessage({'type': 'get_focusing'});

      // Wait for response with timeout
      final response = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _pendingRequest = null;

          final timeoutError =
              'Focus status request timed out after 10s - WebSocket connected: $_isConnected, URL: ${AppConfig.webSocketUrl}';
          _log.severe(timeoutError);
          throw TimeoutException(timeoutError, const Duration(seconds: 10));
        },
      );

      _log.info('Focus status response received');
      return response;
    } catch (e) {
      _pendingRequest = null;
      _log.severe('Focus status request failed: $e');
      rethrow;
    }
  }

  /// Dispose the service and clean up resources
  Future<void> dispose() async {
    _log.info('Disposing WebSocket service');

    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    await _focusUpdatesController.close();

    _cleanup();
  }
}
