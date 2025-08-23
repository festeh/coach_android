import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/websocket_service.dart';
import 'constants/storage_keys.dart';
import 'constants/channel_names.dart';
import 'models/focus_data.dart';

final _log = Logger('BackgroundMonitorHandler');

class BackgroundMonitorHandler {
  
  // Use shared storage keys for consistency between UI and background engines
  
  static MethodChannel? _methodChannel;
  static EventChannel? _eventChannel;
  static StreamSubscription<dynamic>? _appStreamSubscription;
  
  static FocusData _focusData = const FocusData();
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
      _log.info('Loaded state - focusing: ${_focusData.isFocusing}, monitored apps: ${_monitoredPackages.length}');
      
    } catch (e) {
      _log.severe('Failed to initialize background monitor handler: $e');
      rethrow;
    }
  }

  /// Load persisted state from SharedPreferences
  static Future<void> _loadPersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load focus data
      _focusData = FocusData.fromSharedPreferences(
        isFocusing: prefs.getBool(StorageKeys.focusingState) ?? false,
        sinceLastChange: prefs.getInt('sinceLastChange') ?? 0,
        focusTimeLeft: prefs.getInt('focusTimeLeft') ?? 0,
        numFocuses: prefs.getInt('numFocuses') ?? 0,
      );
      
      // Load monitored packages - now reading from same key as UI engine
      final monitoredAppsJson = prefs.getString(StorageKeys.selectedAppPackages);
      if (monitoredAppsJson != null) {
        final List<dynamic> packagesList = jsonDecode(monitoredAppsJson);
        _monitoredPackages = packagesList.cast<String>().toSet();
      }
      
      _log.info('Loaded persisted state - focusing: ${_focusData.isFocusing}, monitored packages: ${_monitoredPackages.join(", ")}');
    } catch (e) {
      _log.severe('Failed to load persisted state: $e');
      // Continue with default values
      _focusData = const FocusData();
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
      _log.info('Overlay decision for $packageName - focusing: ${_focusData.isFocusing}, monitored packages: ${_monitoredPackages.join(", ")}');
      
      // This is the core decision logic (same as in app_monitor.dart)
      final shouldShow = _shouldShowOverlay(packageName);
      
      if (shouldShow) {
        _log.info('SHOWING overlay for app: $packageName (app is monitored AND currently focusing)');
        _showOverlay(packageName);
      } else {
        final isMonitored = _monitoredPackages.contains(packageName);
        if (isMonitored && !_focusData.isFocusing) {
          _log.info('NOT SHOWING overlay for app: $packageName (app is monitored but NOT focusing)');
        } else if (!isMonitored && _focusData.isFocusing) {
          _log.fine('NOT SHOWING overlay for app: $packageName (app is NOT monitored but focusing)');
        } else if (!isMonitored && !_focusData.isFocusing) {
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
    final shouldShow = isMonitored && _focusData.isFocusing;
    
    _log.fine('Overlay decision: packageName=$packageName, isMonitored=$isMonitored, focusing=${_focusData.isFocusing}, shouldShow=$shouldShow');
    
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
    _focusData = _focusData.copyWith(isFocusing: isFocusing);
    _log.info('Focus state updated to: ${_focusData.isFocusing}');
    
    try {
      // Persist the state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.focusingState, _focusData.isFocusing);
      
      // If we're no longer focusing, hide overlay immediately
      if (!_focusData.isFocusing) {
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
  static bool get isFocusing => _focusData.isFocusing;
  
  /// Get current focus data
  static FocusData get focusData => _focusData;

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
          final newFocusData = FocusData.fromWebSocketResponse(data);
          
          // Only update if there's a significant change
          if (_focusData.hasSignificantDifference(newFocusData)) {
            _focusData = newFocusData;
            
            _log.info('Focus data updated from WebSocket: focusing=${_focusData.isFocusing}, sinceLastChange=${_focusData.sinceLastChange}, focusTimeLeft=${_focusData.focusTimeLeft}, numFocuses=${_focusData.numFocuses}');
            
            // Save to SharedPreferences for persistence
            SharedPreferences.getInstance().then((prefs) {
              final dataMap = _focusData.toSharedPreferencesMap();
              prefs.setBool(StorageKeys.focusingState, dataMap['focusing'] as bool);
              prefs.setInt('sinceLastChange', dataMap['sinceLastChange'] as int);
              prefs.setInt('focusTimeLeft', dataMap['focusTimeLeft'] as int);
              prefs.setInt('numFocuses', dataMap['numFocuses'] as int);
            });
            
            // Push update to UI via method channel
            _notifyUIFocusChanged(_focusData.toMethodChannelMap());
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
      await _methodChannel?.invokeMethod('focusStateChanged', data);
      _log.info('Notified UI of focus data: focusing=${_focusData.isFocusing}, sinceLastChange=${_focusData.sinceLastChange}, focusTimeLeft=${_focusData.focusTimeLeft}, numFocuses=${_focusData.numFocuses}');
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
        case 'startFocus':
          return await _startFocus();
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
    
    try {
      // Request fresh focus status from WebSocket server
      _log.info('Background isolate: Requesting focus status from WebSocket');
      final response = await _webSocketService!.requestFocusStatus();
      
      // Update focus data from response
      _focusData = FocusData.fromWebSocketResponse(response);
      
      _log.info('Background isolate: Updated focus state from WebSocket - focusing=${_focusData.isFocusing}, sinceLastChange=${_focusData.sinceLastChange}, focusTimeLeft=${_focusData.focusTimeLeft}, numFocuses=${_focusData.numFocuses}');
      
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      final dataMap = _focusData.toSharedPreferencesMap();
      await prefs.setBool(StorageKeys.focusingState, dataMap['focusing'] as bool);
      await prefs.setInt('sinceLastChange', dataMap['sinceLastChange'] as int);
      await prefs.setInt('focusTimeLeft', dataMap['focusTimeLeft'] as int);
      await prefs.setInt('numFocuses', dataMap['numFocuses'] as int);
      
      // Notify UI with fresh data
      await _notifyUIFocusChanged(_focusData.toMethodChannelMap());
      
      return {'success': true};
    } catch (e) {
      _log.severe('Background isolate: Failed to refresh focus state from WebSocket: $e');
      
      // Fallback: notify UI with current cached state
      await _notifyUIFocusChanged(_focusData.toMethodChannelMap());
      
      throw Exception('Failed to refresh focus state: $e');
    }
  }

  /// Start focus session by sending message to WebSocket server
  static Future<Map<String, dynamic>> _startFocus() async {
    _log.info('Background isolate: Handling start focus request');
    
    if (_webSocketService == null) {
      const error = 'WebSocket service not initialized in background isolate';
      _log.severe(error);
      throw Exception(error);
    }
    
    try {
      // Send focus command to WebSocket server
      await _webSocketService!.sendFocusCommand();
      _log.info('Focus command sent to WebSocket server');
      return {'success': true};
    } catch (e) {
      _log.severe('Failed to send focus command: $e');
      throw Exception('Failed to send focus command: $e');
    }
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
