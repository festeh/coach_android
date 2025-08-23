import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/focus_state.dart';
import '../../models/log_entry.dart';
import '../../services/enhanced_logger.dart';
import '../services/state_service.dart';
import '../../app_monitor.dart' as app_monitor;

final _log = Logger('FocusProvider');

class FocusStateNotifier extends StateNotifier<FocusState> {
  final StateService _stateService;

  FocusStateNotifier(this._stateService) : super(const FocusState()) {
    _loadInitialState();
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
    _log.info('Force fetch requested - for now just refreshing from cache');
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.connection,
      'Refreshing focus state from cache',
    );
    
    // For now, just reload from cache
    // TODO: In the future, implement HTTP request to WebSocket server
    final cachedFocusing = await _stateService.loadFocusingState() ?? false;
    
    state = state.copyWith(
      isFocusing: cachedFocusing,
      status: FocusStatus.ready,
      errorMessage: null,
    );
    
    // Update app monitor
    app_monitor.updateFocusState(cachedFocusing);
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