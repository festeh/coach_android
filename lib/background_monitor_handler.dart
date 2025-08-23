import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/websocket_service.dart';
import 'constants/storage_keys.dart';
import 'constants/channel_names.dart';

final _log = Logger('BackgroundMonitorHandler');

class BackgroundMonitorHandler {
  
  // Use shared storage keys for consistency between UI and background engines
  
  static MethodChannel? _methodChannel;
  static EventChannel? _eventChannel;
  static StreamSubscription<dynamic>? _appStreamSubscription;
  
  static bool _isFocusing = false;
  static Set<String> _monitoredPackages = {};
  static bool _isInitialized = false;
  static WebSocketService? _webSocketService;
  static StreamSubscription<Map<String, dynamic>>? _focusUpdatesSubscription;

  /// Initialize the background monitor handler
  static Future<void> initialize() async {
    if (_isInitialized) {
      _log.warning('Already initialized');
      return;
    }
    
    _log.info('Initializing background monitor handler...');
    
    try {
      // Set up method channel for communication with native service
      _methodChannel = const MethodChannel(ChannelNames.backgroundMethods);
      _eventChannel = const EventChannel(ChannelNames.backgroundEvents);
      
      // Set up method call handler for WebSocket operations from native service
      _methodChannel?.setMethodCallHandler(_handleMethodCall);
      
      // Load persisted state
      await _loadPersistedState();
      
      // Set up listener for app changes from native service
      _setupAppListener();
      
      // Initialize WebSocket service in background
      await _initializeWebSocketService();
      
      // Set up focus updates listener
      _setupFocusUpdatesListener();
      
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
      _isFocusing = prefs.getBool(StorageKeys.focusingState) ?? false;
      
      // Load monitored packages - now reading from same key as UI engine
      final monitoredAppsJson = prefs.getString(StorageKeys.selectedAppPackages);
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
      await prefs.setBool(StorageKeys.focusingState, _isFocusing);
      
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
      await prefs.setString(StorageKeys.selectedAppPackages, jsonEncode(packages.toList()));
    } catch (e) {
      _log.severe('Failed to update monitored packages: $e');
    }
  }

  /// Get current focus state
  static bool get isFocusing => _isFocusing;

  /// Get current monitored packages
  static Set<String> get monitoredPackages => Set.from(_monitoredPackages);

  /// Set up focus updates listener from WebSocket
  static void _setupFocusUpdatesListener() {
    if (_webSocketService == null) {
      _log.warning('Cannot setup focus updates listener - WebSocket service not initialized');
      return;
    }

    try {
      _focusUpdatesSubscription = _webSocketService!.focusUpdates.listen(
        (data) {
          final focusing = data['focusing'] as bool?;
          if (focusing != null && focusing != _isFocusing) {
            _isFocusing = focusing;
            _log.info('Focus state updated from WebSocket: $_isFocusing');
            
            // Save to SharedPreferences for persistence
            SharedPreferences.getInstance().then((prefs) {
              prefs.setBool(StorageKeys.focusingState, _isFocusing);
            });
            
            // Push update to UI via method channel
            _notifyUIFocusChanged(data);
          }
        },
        onError: (error) {
          _log.severe('Error in focus updates stream: $error');
        },
      );
      
      _log.info('Focus updates listener setup complete');
    } catch (e) {
      _log.severe('Failed to setup focus updates listener: $e');
    }
  }

  /// Notify UI of focus state change
  static Future<void> _notifyUIFocusChanged(Map<String, dynamic> data) async {
    try {
      await _methodChannel?.invokeMethod('focusStateChanged', {
        'focusing': _isFocusing,
        'focusTimeLeft': data['focus_time_left'],
        'numFocuses': data['num_focuses'],
      });
      _log.info('Notified UI of focus state: $_isFocusing');
    } catch (e) {
      _log.severe('Failed to notify UI of focus state change: $e');
    }
  }

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
        case 'refreshFocusState':
          return await _refreshFocusState();
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

  /// Refresh focus state by requesting current status from WebSocket and notifying UI
  static Future<Map<String, dynamic>> _refreshFocusState() async {
    _log.info('Background isolate: Handling refresh focus state request');
    
    if (_webSocketService == null) {
      const error = 'WebSocket service not initialized in background isolate';
      _log.severe(error);
      throw Exception(error);
    }
    
    // Just notify UI with current focus state - WebSocket updates will come through the listener
    await _notifyUIFocusChanged({
      'focusing': _isFocusing,
      'focus_time_left': 0,
      'num_focuses': 0,
    });
    
    return {'success': true};
  }

  /// Dispose resources
  static Future<void> dispose() async {
    _log.info('Disposing background monitor handler...');
    
    _isInitialized = false;
    await _appStreamSubscription?.cancel();
    _appStreamSubscription = null;
    
    await _focusUpdatesSubscription?.cancel();
    _focusUpdatesSubscription = null;
    
    // Dispose WebSocket service
    await _webSocketService?.dispose();
    _webSocketService = null;
    
    _methodChannel = null;
    _eventChannel = null;
    
    _log.info('Background monitor handler disposed');
  }
}
