import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import '../models/focus_state.dart';
import '../../models/log_entry.dart';
import '../../services/enhanced_logger.dart';
import '../../services/background_websocket_bridge.dart';
import '../../services/service_event_bus.dart';
import '../services/state_service.dart';
import '../../app_monitor.dart' as app_monitor;

final _log = Logger('FocusProvider');

class FocusStateNotifier extends StateNotifier<FocusState> {
  final StateService _stateService;
  final BackgroundWebSocketBridge _webSocketBridge;
  final ServiceEventBus _eventBus = ServiceEventBus();
  StreamSubscription<ServiceEvent>? _eventSubscription;

  FocusStateNotifier(this._stateService, this._webSocketBridge) : super(const FocusState()) {
    _loadInitialState();
    _setupWebSocketMessageListener();
    _initializeBridgeWithRetry();
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _webSocketBridge.dispose();
    super.dispose();
  }

  /// Initialize the background WebSocket bridge with retry logic
  void _initializeBridgeWithRetry() async {
    try {
      // Wait a moment to allow main.dart service start to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      await _webSocketBridge.initialize();
      _log.info('Background WebSocket bridge initialized');
    } catch (e) {
      _log.severe('Failed to initialize background WebSocket bridge: $e');
      
      // Retry initialization after delay
      _log.info('Will retry bridge initialization in 2 seconds');
      Timer(const Duration(seconds: 2), () async {
        try {
          await _webSocketBridge.initialize();
          _log.info('Background WebSocket bridge initialized on retry');
        } catch (retryError) {
          _log.severe('Bridge initialization retry also failed: $retryError');
          // The bridge will try again when forceFetch is called
        }
      });
    }
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
    _log.info('Force fetch requested - fetching from WebSocket server');
    
    state = state.copyWith(status: FocusStatus.loading);
    
    try {
      EnhancedLogger.info(
        LogSource.ui,
        LogCategory.connection,
        'Requesting focus state from WebSocket server',
      );
      
      // The bridge will automatically ensure it's initialized and service is running
      final response = await _webSocketBridge.requestFocusStatus();
      
      // Process the response
      updateFromWebSocket(response);
      
    } catch (e) {
      _log.severe('Failed to fetch focus state from WebSocket: $e');
      
      EnhancedLogger.error(
        LogSource.ui,
        LogCategory.connection,
        'Failed to fetch focus state from WebSocket server',
        {'error': e.toString()},
      );
      
      // Fall back to cached state
      final cachedFocusing = await _stateService.loadFocusingState() ?? false;
      
      state = state.copyWith(
        isFocusing: cachedFocusing,
        status: FocusStatus.ready,
        errorMessage: 'Failed to connect to server: ${e.toString()}',
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

final backgroundWebSocketBridgeProvider = Provider<BackgroundWebSocketBridge>((ref) => BackgroundWebSocketBridge());

final focusStateProvider = StateNotifierProvider<FocusStateNotifier, FocusState>((ref) {
  final stateService = ref.watch(stateServiceProvider);
  final webSocketBridge = ref.watch(backgroundWebSocketBridgeProvider);
  return FocusStateNotifier(stateService, webSocketBridge);
});