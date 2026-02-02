import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/websocket_service.dart';
import 'services/usage_database.dart';
import 'constants/storage_keys.dart';
import 'constants/channel_names.dart';
import 'constants/focus_data_keys.dart';
import 'models/focus_data.dart';
import 'models/app_rule.dart';

final _log = Logger('BackgroundMonitorHandler');

class BackgroundMonitorHandler {
  
  // Use shared storage keys for consistency between UI and background engines
  
  static MethodChannel? _methodChannel;
  static EventChannel? _eventChannel;
  static StreamSubscription<dynamic>? _appStreamSubscription;
  
  static FocusData _focusData = const FocusData();
  static Set<String> _monitoredPackages = {};
  static Map<String, AppRule> _rules = {};
  static Map<String, String> _pendingChallenges = {}; // ruleId → packageName

  /// Persist pending challenge rule IDs to SharedPreferences so the UI can read them
  static Future<void> _persistPendingChallenges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.pendingChallenges,
      jsonEncode(_pendingChallenges.keys.toList()),
    );
  }
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

      // Initialize usage database
      await UsageDatabase.instance.init();

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
      // In background isolates, the binding may not be fully ready yet.
      // Retry a few times with a delay to allow plugin registration to complete.
      SharedPreferences? prefs;
      for (var attempt = 0; attempt < 5; attempt++) {
        try {
          WidgetsFlutterBinding.ensureInitialized();
          prefs = await SharedPreferences.getInstance();
          break;
        } catch (_) {
          _log.warning('SharedPreferences not ready, retrying (attempt ${attempt + 1})...');
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      if (prefs == null) {
        throw Exception('SharedPreferences unavailable after retries');
      }
      
      // Load focus data
      _focusData = FocusData.fromSharedPreferences(
        isFocusing: prefs.getBool(StorageKeys.focusingState) ?? false,
        sinceLastChange: prefs.getInt('sinceLastChange') ?? 0,
        focusTimeLeft: prefs.getInt('focusTimeLeft') ?? 0,
        numFocuses: prefs.getInt('numFocuses') ?? 0,
        lastNotificationTime: prefs.getInt('lastNotificationTime') ?? 0,
        lastActivityTime: prefs.getInt('lastActivityTime') ?? 0,
        lastFocusEndTime: prefs.getInt('lastFocusEndTime') ?? 0,
      );
      
      // Load monitored packages - now reading from same key as UI engine
      final monitoredAppsJson = prefs.getString(StorageKeys.selectedAppPackages);
      if (monitoredAppsJson != null) {
        final List<dynamic> packagesList = jsonDecode(monitoredAppsJson);
        _monitoredPackages = packagesList.cast<String>().toSet();
      }
      
      // Load rules
      final rulesJson = prefs.getString(StorageKeys.appRules);
      if (rulesJson != null) {
        final Map<String, dynamic> rulesMap = jsonDecode(rulesJson);
        _rules = rulesMap.map((key, value) =>
            MapEntry(key, AppRule.fromJson(value as Map<String, dynamic>)));
      }

      // Cleanup old rule counters
      await UsageDatabase.instance.cleanupOldCounters();

      _log.info('Loaded persisted state - focusing: ${_focusData.isFocusing}, monitored packages: ${_monitoredPackages.join(", ")}, rules: ${_rules.length}');
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
  static Future<void> _handleAppChanged(String packageName) async {
    _log.fine('App changed to: $packageName');

    try {
      // Log app open to usage database
      UsageDatabase.instance.logAppOpened(packageName, _focusData.isFocusing);

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

      // Check rules independently of focus state
      await _checkRules(packageName);

      // Update activity time when user switches apps
      _updateActivityTime();

      // Check focus reminder after handling app change (user activity detected)
      _checkFocusReminder();
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

  /// Check rules for the given package and show overlay if triggered
  static Future<void> _checkRules(String packageName) async {
    // Check for pending challenges first
    final pendingRuleId = _pendingChallenges.entries
        .where((e) => e.value == packageName)
        .map((e) => e.key)
        .cast<String?>()
        .firstOrNull;

    if (pendingRuleId != null) {
      final rule = _rules[pendingRuleId];
      if (rule == null) {
        // Rule was deleted while pending — clean up
        _pendingChallenges.remove(pendingRuleId);
        await _persistPendingChallenges();
        _log.info('Cleaned up pending challenge for deleted rule $pendingRuleId');
      } else {
        _log.info('Re-showing pending challenge for rule ${rule.id} on $packageName');
        await _showRuleOverlay(packageName, rule);
        return;
      }
    }

    final rulesForApp = _rules.values
        .where((r) => r.packageName == packageName)
        .toList();

    if (rulesForApp.isEmpty) return;

    for (final rule in rulesForApp) {
      try {
        final openCount = await UsageDatabase.instance.incrementOpenCount(rule.id);
        _log.info('Rule ${rule.id}: open_count=$openCount for $packageName (everyN=${rule.everyN})');

        if (openCount % rule.everyN == 0) {
          final counters = await UsageDatabase.instance.getCounters(rule.id);
          if (counters.triggerCount < rule.maxTriggers) {
            if (rule.challengeType == 'none') {
              await UsageDatabase.instance.incrementTriggerCount(rule.id);
              _log.info('Rule ${rule.id} triggered! (${counters.triggerCount + 1}/${rule.maxTriggers})');
            } else {
              _pendingChallenges[rule.id] = packageName;
              await _persistPendingChallenges();
              _log.info('Rule ${rule.id} triggered with challenge ${rule.challengeType}, pending completion');
            }
            await _showRuleOverlay(packageName, rule);
            break; // Only one rule popup per app open
          } else {
            _log.info('Rule ${rule.id}: max triggers reached (${counters.triggerCount}/${rule.maxTriggers})');
          }
        }
      } catch (e) {
        _log.severe('Error checking rule ${rule.id}: $e');
      }
    }
  }

  /// Complete a challenge — called from native side
  static Future<void> _completeChallenge(String ruleId) async {
    _pendingChallenges.remove(ruleId);
    await _persistPendingChallenges();
    await UsageDatabase.instance.incrementTriggerCount(ruleId);
    _log.info('Challenge completed for rule $ruleId, trigger count incremented');
    await _hideOverlay();
  }

  /// Show rule overlay via native method channel
  static Future<void> _showRuleOverlay(String packageName, AppRule rule) async {
    try {
      await _methodChannel?.invokeMethod('showOverlay', {
        'packageName': packageName,
        'overlayType': 'rule',
        'challengeType': rule.challengeType,
        'ruleId': rule.id,
      });
      _log.info('Rule overlay shown for package: $packageName (challenge: ${rule.challengeType})');
    } catch (e) {
      _log.severe('Failed to show rule overlay: $e');
    }
  }

  /// Update rules (called when main app changes rules)
  static Future<void> updateRules(Map<String, AppRule> rules) async {
    _rules = rules;
    _log.info('Rules updated: ${rules.length} rules');

    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = rules.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(StorageKeys.appRules, jsonEncode(rulesJson));
    } catch (e) {
      _log.severe('Failed to persist rules: $e');
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

  /// Reload monitored packages from SharedPreferences (called via method channel from native service)
  static Future<Map<String, dynamic>> _reloadMonitoredPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final monitoredAppsJson = prefs.getString(StorageKeys.selectedAppPackages);
      if (monitoredAppsJson != null) {
        final List<dynamic> packagesList = jsonDecode(monitoredAppsJson);
        _monitoredPackages = packagesList.cast<String>().toSet();
      } else {
        _monitoredPackages = {};
      }
      _log.info('Reloaded monitored packages from SharedPreferences: ${_monitoredPackages.length} apps');
      return {'success': true, 'count': _monitoredPackages.length};
    } catch (e) {
      _log.severe('Failed to reload monitored packages: $e');
      return {'success': false, 'error': e.toString()};
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
          // Use updateFromWebSocket to preserve existing timing data and calculate focus end time
          final newFocusData = _focusData.updateFromWebSocket(data);

          // Check if focus session started (was not focusing, now focusing)
          final focusSessionStarted = !_focusData.isFocusing && newFocusData.isFocusing;

          // Check if focus session ended (was focusing, now not focusing)
          final focusSessionEnded = _focusData.isFocusing && !newFocusData.isFocusing;

          // Log focus events to database
          if (focusSessionStarted) {
            UsageDatabase.instance.logFocusStarted();
          }
          if (focusSessionEnded) {
            // sinceLastChange represents how long the focus session lasted
            UsageDatabase.instance.logFocusEnded(_focusData.sinceLastChange);
          }

          // Only update if there's a significant change
          if (_focusData.hasSignificantDifference(newFocusData)) {
            _focusData = newFocusData;

            _log.info('Focus data updated from WebSocket: focusing=${_focusData.isFocusing}, sinceLastChange=${_focusData.sinceLastChange}, focusTimeLeft=${_focusData.focusTimeLeft}, numFocuses=${_focusData.numFocuses}, focusEnded=$focusSessionEnded');

            // Save to SharedPreferences for persistence
            SharedPreferences.getInstance().then((prefs) {
              final dataMap = _focusData.toSharedPreferencesMap();
              prefs.setBool(StorageKeys.focusingState, dataMap['focusing'] as bool);
              prefs.setInt('sinceLastChange', dataMap['sinceLastChange'] as int);
              prefs.setInt('focusTimeLeft', dataMap['focusTimeLeft'] as int);
              prefs.setInt('numFocuses', dataMap['numFocuses'] as int);
              prefs.setInt('lastNotificationTime', dataMap['lastNotificationTime'] as int);
              prefs.setInt('lastActivityTime', dataMap['lastActivityTime'] as int);
              prefs.setInt('lastFocusEndTime', dataMap['lastFocusEndTime'] as int);
            });

            // Push update to UI via method channel
            _notifyUIFocusChanged(_focusData.toMethodChannelMap());

            // Check focus reminder after focus data update
            _checkFocusReminder();
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
      // Add connection status to the data
      final dataWithStatus = Map<String, dynamic>.from(data);
      dataWithStatus[FocusDataKeys.isConnected] = _webSocketService?.isConnected ?? false;

      await _methodChannel?.invokeMethod('focusStateChanged', dataWithStatus);
      _log.info('Notified UI of focus data: focusing=${_focusData.isFocusing}, connected=${dataWithStatus[FocusDataKeys.isConnected]}');
    } catch (e) {
      _log.severe('Failed to notify UI of focus state change: $e');
    }
  }

  /// Update activity time when user is active
  static Future<void> _updateActivityTime() async {
    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _focusData = _focusData.copyWith(lastActivityTime: currentTime);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastActivityTime', currentTime);

      _log.info('Activity time updated: $currentTime - immediately pushing to UI');

      // Immediately push updated data to UI
      await _notifyUIFocusChanged(_focusData.toMethodChannelMap());
    } catch (e) {
      _log.severe('Failed to update activity time: $e');
    }
  }

  /// Update notification time when reminder is shown
  static Future<void> updateNotificationTime() async {
    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _focusData = _focusData.copyWith(lastNotificationTime: currentTime);

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastNotificationTime', currentTime);

      _log.info('Notification time updated: $currentTime - immediately pushing to UI');

      // Immediately push updated data to UI
      await _notifyUIFocusChanged(_focusData.toMethodChannelMap());
    } catch (e) {
      _log.severe('Failed to update notification time: $e');
    }
  }

  /// Check if focus reminder should be shown
  static Future<void> _checkFocusReminder() async {
    try {
      final data = _focusData.toMethodChannelMap();
      await _methodChannel?.invokeMethod('checkFocusReminder', data);
      _log.fine('Requested focus reminder check: focusing=${_focusData.isFocusing}, sinceLastChange=${_focusData.sinceLastChange}');
    } catch (e) {
      _log.severe('Failed to check focus reminder: $e');
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
        case 'updateNotificationTime':
          await updateNotificationTime();
          return {'success': true};
        case 'forceShowFocusReminder':
          return await _forceShowFocusReminder();
        case 'reloadMonitoredPackages':
          return await _reloadMonitoredPackages();
        case 'challengeCompleted':
          final args = call.arguments as Map<dynamic, dynamic>?;
          final ruleId = args?['ruleId'] as String?;
          if (ruleId != null) {
            await _completeChallenge(ruleId);
            return {'success': true};
          }
          throw PlatformException(
            code: 'INVALID_ARGS',
            message: 'ruleId is required for challengeCompleted',
          );
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
      
      // Update focus data from response, preserving existing timing data
      _focusData = _focusData.updateFromWebSocket(response);

      _log.info('Background isolate: Updated focus state from WebSocket - focusing=${_focusData.isFocusing}, sinceLastChange=${_focusData.sinceLastChange}, focusTimeLeft=${_focusData.focusTimeLeft}, numFocuses=${_focusData.numFocuses}');
      
      // Save to SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      final dataMap = _focusData.toSharedPreferencesMap();
      await prefs.setBool(StorageKeys.focusingState, dataMap['focusing'] as bool);
      await prefs.setInt('sinceLastChange', dataMap['sinceLastChange'] as int);
      await prefs.setInt('focusTimeLeft', dataMap['focusTimeLeft'] as int);
      await prefs.setInt('numFocuses', dataMap['numFocuses'] as int);
      await prefs.setInt('lastNotificationTime', dataMap['lastNotificationTime'] as int);
      await prefs.setInt('lastActivityTime', dataMap['lastActivityTime'] as int);
      await prefs.setInt('lastFocusEndTime', dataMap['lastFocusEndTime'] as int);
      
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

  /// Force show focus reminder (debug mode)
  static Future<Map<String, dynamic>> _forceShowFocusReminder() async {
    _log.info('Background isolate: Force showing focus reminder (debug mode)');

    try {
      // Call the Android PopNotificationManager directly
      await _methodChannel?.invokeMethod('forceShowReminderDirect');

      // Update notification time tracking
      await updateNotificationTime();

      _log.info('Background isolate: Force focus reminder completed successfully');
      return {'success': true};
    } catch (e) {
      _log.severe('Background isolate: Failed to force show focus reminder: $e');
      throw Exception('Failed to force show focus reminder: $e');
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
