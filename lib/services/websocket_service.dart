import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:logging/logging.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config.dart';
import '../models/log_entry.dart';
import 'enhanced_logger.dart';
import 'service_event_bus.dart';

final _log = Logger('WebSocketService');

class WebSocketService {
  static final _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();
  
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  
  bool _isConnected = false;
  bool _isConnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};
  final _eventBus = ServiceEventBus();
  
  bool get isConnected => _isConnected;
  
  /// Initialize and connect to WebSocket server
  Future<void> initialize() async {
    if (AppConfig.webSocketUrl.isEmpty) {
      _log.warning('WebSocket URL not configured');
      EnhancedLogger.warning(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket URL not configured - cannot connect',
      );
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
      EnhancedLogger.info(
        LogSource.webSocket,
        LogCategory.connection,
        'Attempting WebSocket connection',
        {'url': AppConfig.webSocketUrl},
      );
      
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
      
      _startHeartbeat();
      _updateConnectionStatus(true);
      
      _log.info('WebSocket connected successfully');
      EnhancedLogger.info(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket connected successfully',
      );
      
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
      
      EnhancedLogger.debug(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket message received',
        {'type': messageType, 'data': data},
      );
      
      // Handle response to pending requests
      // Map server response types to our request types
      String? requestKey;
      if (messageType == 'focusing_status' || (messageType == null && data.containsKey('focusing'))) {
        requestKey = 'focusing_status';
      } else if (messageType != null) {
        requestKey = messageType;
      }
      
      if (requestKey != null && _pendingRequests.containsKey(requestKey)) {
        final completer = _pendingRequests.remove(requestKey);
        completer?.complete(data);
        return;
      }
      
      // Broadcast message to interested parties via event bus
      _eventBus.emit(ServiceEvent(
        type: ServiceEventType.webSocketMessage,
        message: 'WebSocket message received',
        data: data,
      ));
      
    } catch (e) {
      _log.severe('Error processing WebSocket message: $e');
      EnhancedLogger.error(
        LogSource.webSocket,
        LogCategory.connection,
        'Error processing WebSocket message',
        {'error': e.toString(), 'message': message},
      );
    }
  }
  
  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    _log.severe('WebSocket error: $error');
    EnhancedLogger.error(
      LogSource.webSocket,
      LogCategory.connection,
      'WebSocket connection error',
      {'error': error.toString()},
    );
    
    _cleanup();
    _scheduleReconnect();
  }
  
  /// Handle WebSocket disconnect
  void _handleDisconnect() {
    _log.info('WebSocket disconnected');
    EnhancedLogger.info(
      LogSource.webSocket,
      LogCategory.connection,
      'WebSocket connection closed',
    );
    
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
    
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    _updateConnectionStatus(false);
    
    // Complete any pending requests with error
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(Exception('WebSocket connection lost'));
      }
    }
    _pendingRequests.clear();
  }
  
  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect() {
    if (_reconnectTimer != null) return;
    
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _log.severe('Max reconnection attempts reached. Giving up.');
      EnhancedLogger.error(
        LogSource.webSocket,
        LogCategory.connection,
        'Max WebSocket reconnection attempts reached',
        {'attempts': _reconnectAttempts},
      );
      return;
    }
    
    _reconnectAttempts++;
    
    // Exponential backoff with jitter
    final delay = Duration(
      milliseconds: _baseReconnectDelay.inMilliseconds * 
                   pow(2, min(_reconnectAttempts - 1, 6)).toInt() +
                   Random().nextInt(1000),
    );
    
    _log.info('Scheduling reconnection attempt $_reconnectAttempts in ${delay.inSeconds}s');
    EnhancedLogger.info(
      LogSource.webSocket,
      LogCategory.connection,
      'Scheduling WebSocket reconnection',
      {'attempt': _reconnectAttempts, 'delaySeconds': delay.inSeconds},
    );
    
    _eventBus.emitSimple(ServiceEventType.webSocketReconnecting, 
                        'Reconnecting in ${delay.inSeconds}s');
    
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      _connect();
    });
  }
  
  /// Start heartbeat timer to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (_isConnected) {
        _sendMessage({'type': 'ping'});
      }
    });
  }
  
  /// Update connection status with health monitor and event bus
  void _updateConnectionStatus(bool connected) {
    // Emit event for health monitoring - the health monitor will listen to these events
    // This avoids circular dependency issues
    if (connected) {
      _eventBus.emitSimple(ServiceEventType.webSocketConnected, 
                          'WebSocket connected');
    } else {
      _eventBus.emitSimple(ServiceEventType.webSocketDisconnected, 
                          'WebSocket disconnected');
    }
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
      EnhancedLogger.debug(
        LogSource.webSocket,
        LogCategory.connection,
        'WebSocket message sent',
        message,
      );
    } catch (e) {
      _log.severe('Failed to send WebSocket message: $e');
      throw Exception('Failed to send WebSocket message: $e');
    }
  }
  
  /// Request focus status from WebSocket server
  /// This is the abstracted method that handles connection management
  Future<Map<String, dynamic>> requestFocusStatus() async {
    _log.info('Requesting focus status from WebSocket');
    
    // Check if connected, if not try to connect
    if (!_isConnected) {
      _log.info('WebSocket not connected, attempting to connect first');
      await _connect();
      
      // Wait a bit for connection to establish
      for (int i = 0; i < 50 && !_isConnected; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      if (!_isConnected) {
        final errorMsg = 'Could not establish WebSocket connection after 5 seconds. URL: ${AppConfig.webSocketUrl}';
        _log.severe(errorMsg);
        throw Exception(errorMsg);
      }
      _log.info('WebSocket connection established successfully');
    }
    
    // Create a completer for this request
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests['focusing_status'] = completer;
    
    try {
      // Send the request
      await _sendMessage({'type': 'get_focusing'});
      
      EnhancedLogger.info(
        LogSource.webSocket,
        LogCategory.connection,
        'Focus status request sent',
      );
      
      // Wait for response with timeout
      final response = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          _pendingRequests.remove('focusing_status');
          throw TimeoutException('Focus status request timed out', const Duration(seconds: 10));
        },
      );
      
      EnhancedLogger.info(
        LogSource.webSocket,
        LogCategory.connection,
        'Focus status response received',
        response,
      );
      
      return response;
      
    } catch (e) {
      _pendingRequests.remove('focusing_status');
      _log.severe('Focus status request failed: $e');
      
      EnhancedLogger.error(
        LogSource.webSocket,
        LogCategory.connection,
        'Focus status request failed',
        {'error': e.toString()},
      );
      
      rethrow;
    }
  }
  
  /// Dispose the service and clean up resources
  Future<void> dispose() async {
    _log.info('Disposing WebSocket service');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    _cleanup();
  }
}