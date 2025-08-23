import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../models/focus_state.dart';
import '../../models/log_entry.dart';
import '../../services/enhanced_logger.dart';
import '../../services/service_event_bus.dart';
import '../services/state_service.dart';
import '../../app_monitor.dart' as app_monitor;

final _log = Logger('FocusProvider');

class FocusStateNotifier extends StateNotifier<FocusState> {
  final StateService _stateService;
  final ServiceEventBus _eventBus = ServiceEventBus();
  StreamSubscription<ServiceEvent>? _eventSubscription;

  FocusStateNotifier(this._stateService) : super(const FocusState()) {
    _loadInitialState();
    // _setupWebSocketMessageListener(); // Disabled - background is now source of truth
    _setupMethodChannelHandler();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }


  void _setupWebSocketMessageListener() {
    _eventSubscription = _eventBus.events.listen((event) {
      if (event.type == ServiceEventType.webSocketMessage) {
        final data = event.data;
        if (data != null) {
          // Check if this is a focus status message
          if (data.containsKey('focusing') || data['type'] == 'focusing_status') {
            updateFromWebSocket(data);
          }
        }
      }
    });
  }

  void _setupMethodChannelHandler() {
    const MethodChannel('foreground_app_monitor')
        .setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'focusStateChanged':
          final data = call.arguments as Map<String, dynamic>;
          _log.info('Received focus state change from background: $data');
          
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
    
    // Update app monitor with initial focus state
    app_monitor.updateFocusState(cachedFocusing);
    
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.system,
      'Initial focus state loaded from cache',
      {'focusing': cachedFocusing},
    );
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

    // Update app monitor with new focus state
    app_monitor.updateFocusState(isFocusing);

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
      
      // Send refresh request to background isolate via method channel
      const MethodChannel('com.example.coach_android/background')
          .invokeMethod('refreshFocusState');
      
      _log.info('Refresh request sent to background isolate');
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
      
      // Update app monitor with cached state
      app_monitor.updateFocusState(cachedFocusing);
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
    
    // Update app monitor with new focus state
    app_monitor.updateFocusState(focusing);
    
    // Persist to cache
    _stateService.saveFocusingState(focusing);
  }
}

final stateServiceProvider = Provider<StateService>((ref) => StateService());

final focusStateProvider = StateNotifierProvider<FocusStateNotifier, FocusState>((ref) {
  final stateService = ref.watch(stateServiceProvider);
  return FocusStateNotifier(stateService);
});