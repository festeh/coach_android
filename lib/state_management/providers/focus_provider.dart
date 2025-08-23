import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import '../models/focus_state.dart';
import '../../models/log_entry.dart';
import '../../services/enhanced_logger.dart';
import '../services/state_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/storage_keys.dart';
import '../../constants/channel_names.dart';

final _log = Logger('FocusProvider');

class FocusStateNotifier extends StateNotifier<FocusState> {
  final StateService _stateService;

  FocusStateNotifier(this._stateService) : super(const FocusState()) {
    _loadInitialState();
    // _setupWebSocketMessageListener(); // Disabled - background is now source of truth
    _setupMethodChannelHandler();
  }




  static const MethodChannel _methodChannel = MethodChannel(ChannelNames.mainMethods);

  void _setupMethodChannelHandler() {
    _log.info('Setting up method channel handler on: ${ChannelNames.mainMethods}');
    _log.info('Method channel instance: $_methodChannel');
    _methodChannel.setMethodCallHandler(_handleMethodCall);
    _log.info('Method channel handler set up complete on: $_methodChannel');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    _log.info('=== METHOD CALL RECEIVED ===');
    _log.info('Method: ${call.method}');
    _log.info('Arguments: ${call.arguments}');
    _log.info('=== END METHOD CALL INFO ===');
    
    try {
      switch (call.method) {
        case 'focusStateChanged':
          _log.info('=== PROCESSING FOCUS STATE CHANGED ===');
          final data = Map<String, dynamic>.from(call.arguments as Map);
          _log.info('Focus state data: $data');
          
          // Update state from background notification
          await updateFocusState(
            isFocusing: data['focusing'] as bool,
            numFocuses: data['numFocuses'] as int?,
            focusTimeLeft: (data['focusTimeLeft'] as num?)?.toDouble(),
          );
          
          EnhancedLogger.info(
            LogSource.ui,
            LogCategory.system,
            'Focus state updated from background',
            data,
          );
          
          return null;
        default:
          _log.warning('Unknown method call from background: ${call.method}');
          return null;
      }
    } catch (e) {
      _log.severe('Error handling method call from background: $e');
      return null;
    }
  }

  Future<void> _loadInitialState() async {
    // Load cached state initially
    final cachedFocusing = await _stateService.loadFocusingState() ?? false;
    
    state = state.copyWith(
      isFocusing: cachedFocusing,
      status: FocusStatus.ready,
    );
    
    // Sync initial focus state to background
    await _syncFocusStateToBackground(cachedFocusing);
    
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.system,
      'Initial focus state loaded from cache',
      {'focusing': cachedFocusing},
    );
    
    // Request current state from background isolate to ensure sync
    await forceFetch();
  }

  Future<void> updateFocusState({
    required bool isFocusing,
    int? numFocuses,
    double? focusTimeLeft,
  }) async {
    _log.info('Updating focus state: focusing=$isFocusing, numFocuses=$numFocuses, timeLeft=$focusTimeLeft');
    
    state = state.copyWith(
      isFocusing: isFocusing,
      numFocuses: numFocuses ?? state.numFocuses,
      focusTimeLeft: focusTimeLeft ?? state.focusTimeLeft,
      status: FocusStatus.ready,
    );

    // Sync focus state to background isolate
    await _syncFocusStateToBackground(isFocusing);

    // Persist for caching
    await _stateService.saveFocusingState(isFocusing);
  }

  Future<void> forceFetch() async {
    _log.info('Force fetch requested - requesting refresh from background isolate');
    
    state = state.copyWith(status: FocusStatus.loading);
    
    try {
      EnhancedLogger.info(
        LogSource.ui,
        LogCategory.connection,
        'Requesting focus state refresh from background isolate',
      );
      
      // Send refresh request via the plugin method channel
      _methodChannel.invokeMethod('requestFocusStateRefresh');
      
      _log.info('Refresh request sent to background isolate');
      
      // Test if method channel works in reverse - call a test method
      _log.info('Testing reverse method call...');
      try {
        final result = await _methodChannel.invokeMethod('testMethodCall');
        _log.info('Test method call result: $result');
      } catch (e) {
        _log.severe('Test method call failed: $e');
      }
      // The background isolate will respond via focusStateChanged method call
      
    } catch (e) {
      _log.severe('Failed to request focus state refresh: $e');
      
      EnhancedLogger.error(
        LogSource.ui,
        LogCategory.connection,
        'Failed to request focus state refresh from background',
        {'error': e.toString()},
      );
      
      // Fall back to cached state
      final cachedFocusing = await _stateService.loadFocusingState() ?? false;
      
      state = state.copyWith(
        isFocusing: cachedFocusing,
        status: FocusStatus.ready,
        errorMessage: 'Failed to refresh focus state: ${e.toString()}',
      );
      
      // Sync cached state to background
      await _syncFocusStateToBackground(cachedFocusing);
    }
  }

  // Sync focus state to SharedPreferences for background isolate
  Future<void> _syncFocusStateToBackground(bool focusing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(StorageKeys.focusingState, focusing);
      _log.info('Synced focus state to background: $focusing');
    } catch (e) {
      _log.severe('Failed to sync focus state to background: $e');
    }
  }

  void updateFromWebSocket(Map<String, dynamic> data) {
    final focusing = data['focusing'] as bool? ?? false;
    final numFocuses = data['num_focuses'] as int? ?? 0;
    final timeLeft = (data['focus_time_left'] as int? ?? 0) / 60;
    
    EnhancedLogger.info(
      LogSource.webSocket,
      LogCategory.connection,
      'Focus status response received from WebSocket',
      {
        'focusing': focusing,
        'numFocuses': numFocuses,
        'timeLeft': timeLeft,
        'responseType': data['type'] ?? 'status_update',
      },
    );
    
    // Update state and mark as ready since we got a response
    state = state.copyWith(
      isFocusing: focusing,
      numFocuses: numFocuses,
      focusTimeLeft: timeLeft,
      status: FocusStatus.ready,
      errorMessage: null,
    );
    
    // Sync focus state to background isolate
    _syncFocusStateToBackground(focusing);
    
    // Persist to cache
    _stateService.saveFocusingState(focusing);
  }
}

final stateServiceProvider = Provider<StateService>((ref) => StateService());

final focusStateProvider = StateNotifierProvider<FocusStateNotifier, FocusState>((ref) {
  final stateService = ref.watch(stateServiceProvider);
  return FocusStateNotifier(stateService);
});