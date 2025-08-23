import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('BackgroundWebSocketBridge');

/// Bridge service to communicate with WebSocket running in background isolate
class BackgroundWebSocketBridge {
  static final _instance = BackgroundWebSocketBridge._internal();
  factory BackgroundWebSocketBridge() => _instance;
  BackgroundWebSocketBridge._internal();

  static const String _methodChannelName = 'com.example.foreground_app_monitor/methods';
  MethodChannel? _methodChannel;
  
  bool _isInitialized = false;

  /// Initialize the bridge to communicate with background WebSocket
  Future<void> initialize() async {
    if (_isInitialized) {
      _log.warning('Bridge already initialized');
      return;
    }

    _log.info('Initializing background WebSocket bridge');
    
    try {
      _methodChannel = const MethodChannel(_methodChannelName);
      
      // Initialize WebSocket in background isolate
      await _methodChannel?.invokeMethod('initializeWebSocket');
      
      _isInitialized = true;
      _log.info('Background WebSocket bridge initialized successfully');
    } catch (e) {
      _log.severe('Failed to initialize background WebSocket bridge: $e');
      rethrow;
    }
  }

  /// Request focus status from background WebSocket
  Future<Map<String, dynamic>> requestFocusStatus() async {
    if (!_isInitialized || _methodChannel == null) {
      throw Exception('Background WebSocket bridge not initialized');
    }

    _log.info('Requesting focus status from background WebSocket');
    
    try {
      final result = await _methodChannel!.invokeMethod('requestFocusStatus');
      
      if (result is Map) {
        final response = Map<String, dynamic>.from(result);
        _log.info('Focus status received from background: $response');
        return response;
      } else {
        throw Exception('Invalid response format from background WebSocket');
      }
    } catch (e) {
      _log.severe('Failed to request focus status from background: $e');
      rethrow;
    }
  }

  /// Check if bridge is initialized
  bool get isInitialized => _isInitialized;

  /// Dispose the bridge
  Future<void> dispose() async {
    if (!_isInitialized) return;
    
    _log.info('Disposing background WebSocket bridge');
    
    try {
      // Dispose WebSocket in background isolate
      await _methodChannel?.invokeMethod('disposeWebSocket');
    } catch (e) {
      _log.warning('Error disposing background WebSocket: $e');
    }
    
    _methodChannel = null;
    _isInitialized = false;
    
    _log.info('Background WebSocket bridge disposed');
  }
}