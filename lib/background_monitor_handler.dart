import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/websocket_service.dart';

final _log = Logger('BackgroundMonitorHandler');

class BackgroundMonitorHandler {
  static const String _methodChannelName = 'com.example.coach_android/background';
  static const String _eventChannelName = 'com.example.coach_android/background_events';
  
  static const String _focusStateKey = 'background_focus_state';
  static const String _monitoredAppsKey = 'background_monitored_apps';
  
  static MethodChannel? _methodChannel;
  static EventChannel? _eventChannel;
  static StreamSubscription<dynamic>? _appStreamSubscription;
  
  static bool _isFocusing = false;
  static Set<String> _monitoredPackages = {};
  static bool _isInitialized = false;
  static WebSocketService? _webSocketService;

  /// Initialize the background monitor handler
  static Future<void> initialize() async {
    if (_isInitialized) {
      _log.warning('Already initialized');
      return;
    }
    
    _log.info('Initializing background monitor handler...');
    
    try {
      // Set up method channel for communication with native service
      _methodChannel = const MethodChannel(_methodChannelName);
      _eventChannel = const EventChannel(_eventChannelName);
      
      // Set up method call handler for WebSocket operations from native service
      _methodChannel?.setMethodCallHandler(_handleMethodCall);
      
      // Load persisted state
      await _loadPersistedState();
      
      // Set up listener for app changes from native service
      _setupAppListener();
      
      // Initialize WebSocket service in background
      await _initializeWebSocketService();
      
      // Notify native service that background isolate is ready
      await _methodChannel?.invokeMethod('backgroundReady');
      
      _isInitialized = true;
      _log.info('Background monitor handler initialized successfully');
      
      // Log current state for debugging
      _log.info('Loaded state - isFocusing: $_isFocusing, monitored apps: ${_monitoredPackages.length}');
      
    } catch (e) {
      _log.severe('Failed to initialize background monitor handler: $e');
      rethrow;
    }
  }

  /// Load persisted state from SharedPreferences
  static Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load focus state
      _isFocusing = prefs.getBool(_focusStateKey) ?? false;
      
      // Load monitored packages
      final monitoredAppsJson = prefs.getString(_monitoredAppsKey);
      if (monitoredAppsJson != null) {
        final List<dynamic> packagesList = jsonDecode(monitoredAppsJson);
        _monitoredPackages = packagesList.cast<String>().toSet();
      }
      
      _log.info('Loaded persisted state - isFocusing: $_isFocusing, monitored packages: ${_monitoredPackages.join(", ")}');
    } catch (e) {
      _log.severe('Failed to load persisted state: $e');
      // Continue with default values
      _isFocusing = false;
      _monitoredPackages = {};
    }
  }

  /// Set up listener for app changes from the native service
  static void _setupAppListener() {
    try {
      _appStreamSubscription = _eventChannel?.receiveBroadcastStream().listen(
        (dynamic data) {
          if (data is String) {
            _handleAppChanged(data);
          } else {
            _log.warning('Received non-String app data: $data');
          }
        },
        onError: (error) {
          _log.severe('Error in app stream: $error');
          // Try to reconnect after a delay
          Timer(const Duration(seconds: 5), () {
            if (!_isInitialized) return;
            _log.info('Attempting to reconnect app listener...');
            _setupAppListener();
          });
        },
        onDone: () {
          _log.info('App stream closed');
        },
      );
      
      _log.info('App listener setup complete');
    } catch (e) {
      _log.severe('Failed to setup app listener: $e');
    }
  }

  /// Handle when a new app becomes foreground
  static void _handleAppChanged(String packageName) {
    _log.fine('App changed to: $packageName');
    
    try {
      // Log current state for debugging
      _log.info('Overlay decision for $packageName - isFocusing: $_isFocusing, monitored packages: ${_monitoredPackages.join(", ")}');
      
      // This is the core decision logic (same as in app_monitor.dart)
      final shouldShow = _shouldShowOverlay(packageName);
      
      if (shouldShow) {
        _log.info('SHOWING overlay for app: $packageName (app is monitored AND currently focusing)');
        _showOverlay(packageName);
      } else {
        final isMonitored = _monitoredPackages.contains(packageName);
        if (isMonitored && !_isFocusing) {
          _log.info('NOT SHOWING overlay for app: $packageName (app is monitored but NOT focusing)');
        } else if (!isMonitored && _isFocusing) {
          _log.fine('NOT SHOWING overlay for app: $packageName (app is NOT monitored but focusing)');
        } else if (!isMonitored && !_isFocusing) {
          _log.fine('NOT SHOWING overlay for app: $packageName (app is NOT monitored and NOT focusing)');
        }
        _hideOverlay();
      }
    } catch (e) {
      _log.severe('Error handling app change: $e');
    }
  }

  /// Determine if overlay should be shown (matches logic from app_monitor.dart)
  static bool _shouldShowOverlay(String packageName) {
    final isMonitored = _monitoredPackages.contains(packageName);
    final shouldShow = isMonitored && _isFocusing;
    
    _log.fine('Overlay decision: packageName=$packageName, isMonitored=$isMonitored, isFocusing=$_isFocusing, shouldShow=$shouldShow');
    
    return shouldShow;
  }

  /// Show overlay via native method channel
  static Future<void> _showOverlay(String packageName) async {
    try {
      await _methodChannel?.invokeMethod('showOverlay', {'packageName': packageName});
      _log.info('Overlay shown for package: $packageName');
    } catch (e) {
      _log.severe('Failed to show overlay: $e');
    }
  }

  /// Hide overlay via native method channel
  static Future<void> _hideOverlay() async {
    try {
      await _methodChannel?.invokeMethod('hideOverlay');
      _log.fine('Overlay hidden');
    } catch (e) {
      _log.severe('Failed to hide overlay: $e');
    }
  }

  /// Update focus state (called when main app changes focus state)
  static Future<void> updateFocusState(bool isFocusing) async {
    _isFocusing = isFocusing;
    _log.info('Focus state updated to: $_isFocusing');
    
    try {
      // Persist the state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_focusStateKey, _isFocusing);
      
      // If we're no longer focusing, hide overlay immediately
      if (!_isFocusing) {
        await _hideOverlay();
      }
    } catch (e) {
      _log.severe('Failed to update focus state: $e');
    }
  }

  /// Update monitored packages (called when main app changes monitored apps)
  static Future<void> updateMonitoredPackages(Set<String> packages) async {
    _monitoredPackages = packages;
    _log.info('Monitored packages updated: ${packages.length} apps');
    
    try {
      // Persist the packages
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_monitoredAppsKey, jsonEncode(packages.toList()));
    } catch (e) {
      _log.severe('Failed to update monitored packages: $e');
    }
  }

  /// Get current focus state
  static bool get isFocusing => _isFocusing;

  /// Get current monitored packages
  static Set<String> get monitoredPackages => Set.from(_monitoredPackages);

  /// Initialize WebSocket service in background
  static Future<void> _initializeWebSocketService() async {
    _log.info('Background isolate: Initializing WebSocket service...');
    
    try {
      _webSocketService = WebSocketService();
      await _webSocketService!.initialize();
      
      // Verify the connection is working
      final isConnected = _webSocketService!.isConnected;
      _log.info('Background isolate: WebSocket service initialized - Connected: $isConnected');
      
      if (!isConnected) {
        _log.warning('Background isolate: WebSocket service initialized but not connected');
      }
    } catch (e) {
      final errorMsg = 'Failed to initialize WebSocket service in background isolate: $e';
      _log.severe(errorMsg);
      _webSocketService = null;
      
      // Don't rethrow - let the system continue and handle errors when requests are made
    }
  }

  /// Handle method calls from main isolate
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    _log.fine('Received method call: ${call.method}');
    
    try {
      switch (call.method) {
        case 'requestFocusStatus':
          return await _requestFocusStatus();
        case 'initializeWebSocket':
          await _initializeWebSocketService();
          return {'success': true};
        case 'disposeWebSocket':
          await _webSocketService?.dispose();
          _webSocketService = null;
          return {'success': true};
        default:
          throw PlatformException(
            code: 'UNKNOWN_METHOD',
            message: 'Unknown method: ${call.method}',
          );
      }
    } catch (e) {
      _log.severe('Error handling method call ${call.method}: $e');
      throw PlatformException(
        code: 'METHOD_ERROR', 
        message: 'Error handling ${call.method}: $e',
      );
    }
  }

  /// Request focus status via WebSocket
  static Future<Map<String, dynamic>> _requestFocusStatus() async {
    _log.info('Background isolate: Handling focus status request');
    
    if (_webSocketService == null) {
      const error = 'WebSocket service not initialized in background isolate';
      _log.severe(error);
      throw Exception(error);
    }
    
    // Log detailed connection status for debugging
    if (_webSocketService != null) {
      final connectionStatus = _webSocketService!.getConnectionStatus();
      _log.info('Background isolate: WebSocket connection status: $connectionStatus');
    }
    
    try {
      // Add a timeout wrapper around the WebSocket request
      final response = await _webSocketService!.requestFocusStatus().timeout(
        const Duration(seconds: 12), // Slightly longer than the internal timeout
        onTimeout: () {
          _log.severe('Background isolate: Focus status request timed out after 12 seconds');
          throw TimeoutException('Background WebSocket request timed out', const Duration(seconds: 12));
        },
      );
      
      _log.info('Background isolate: Focus status response received: $response');
      return response;
    } on TimeoutException catch (e) {
      final errorMsg = 'Background isolate: WebSocket focus status request timed out: $e';
      _log.severe(errorMsg);
      
      // Try to reinitialize WebSocket service for next request
      try {
        _log.info('Background isolate: Attempting to reinitialize WebSocket service after timeout');
        await _webSocketService?.dispose();
        await _initializeWebSocketService();
      } catch (reinitError) {
        _log.severe('Background isolate: Failed to reinitialize WebSocket service: $reinitError');
      }
      
      throw Exception(errorMsg);
    } catch (e) {
      final errorMsg = 'Background isolate: Failed to request focus status: $e';
      _log.severe(errorMsg);
      
      // Check if it's a connection issue and try to reinitialize
      if (e.toString().contains('WebSocket') || e.toString().contains('connection')) {
        try {
          _log.info('Background isolate: Connection error detected, attempting to reinitialize WebSocket service');
          await _webSocketService?.dispose();
          await _initializeWebSocketService();
        } catch (reinitError) {
          _log.severe('Background isolate: Failed to reinitialize WebSocket service: $reinitError');
        }
      }
      
      throw Exception(errorMsg);
    }
  }

  /// Dispose resources
  static Future<void> dispose() async {
    _log.info('Disposing background monitor handler...');
    
    _isInitialized = false;
    await _appStreamSubscription?.cancel();
    _appStreamSubscription = null;
    
    // Dispose WebSocket service
    await _webSocketService?.dispose();
    _webSocketService = null;
    
    _methodChannel = null;
    _eventChannel = null;
    
    _log.info('Background monitor handler disposed');
  }
}