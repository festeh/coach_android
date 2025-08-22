import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logging/logging.dart';
import '../models/focus_state.dart';
import '../../models/log_entry.dart';
import '../../services/enhanced_logger.dart';
import '../../config.dart';
import '../services/state_service.dart';

final _log = Logger('FocusProvider');

class FocusStateNotifier extends StateNotifier<FocusState> {
  final StateService _stateService;

  FocusStateNotifier(this._stateService) : super(const FocusState()) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    // Don't load from local storage on init - WebSocket is the source of truth
    // Just request fresh data from WebSocket
    state = state.copyWith(status: FocusStatus.loading);
    
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.connection,
      'Initial load - requesting focus status from WebSocket',
      {'endpoint': AppConfig.webSocketUrl},
    );
    
    final service = FlutterBackgroundService();
    service.invoke('requestFocusStatus');
    
    // Wait for WebSocket response
    await Future.delayed(const Duration(seconds: 2));
    
    // If still loading, show error
    if (state.status == FocusStatus.loading) {
      state = state.copyWith(
        status: FocusStatus.error,
        errorMessage: 'Unable to connect to server',
        isFocusing: false,
      );
    }
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

    // Note: We only persist for display caching, WebSocket is source of truth
    await _stateService.saveFocusingState(isFocusing);
  }

  Future<void> forceFetch() async {
    _log.info('Force fetching focus state from WebSocket');
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.connection,
      'Requesting fresh focus status from WebSocket',
      {'endpoint': AppConfig.webSocketUrl},
    );
    
    state = state.copyWith(status: FocusStatus.loading);
    
    // Request fresh data from the background service/WebSocket
    final service = FlutterBackgroundService();
    
    // Check if service is running
    final isRunning = await service.isRunning();
    // ignore: avoid_print
    print('FocusProvider: Background service running: $isRunning');
    
    // ignore: avoid_print
    print('FocusProvider: Invoking requestFocusStatus on background service');
    service.invoke('requestFocusStatus');
    // ignore: avoid_print
    print('FocusProvider: Invoked requestFocusStatus');
    
    // Wait for WebSocket response
    await Future.delayed(const Duration(seconds: 2));
    
    // If still loading after WebSocket request timeout, show error
    if (state.status == FocusStatus.loading) {
      EnhancedLogger.error(
        LogSource.ui,
        LogCategory.connection,
        'WebSocket request timeout - no response received',
        {'endpoint': AppConfig.webSocketUrl, 'timeout': '2 seconds'},
      );
      
      // Invalidate cache and show error state
      await _stateService.saveFocusingState(false);
      
      state = state.copyWith(
        status: FocusStatus.error,
        errorMessage: 'Unable to connect to server',
        isFocusing: false,
        numFocuses: 0,
        focusTimeLeft: 0,
      );
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
    
    // Still persist to cache for display purposes only (not as source of truth)
    _stateService.saveFocusingState(focusing);
  }
}

final stateServiceProvider = Provider<StateService>((ref) => StateService());

final focusStateProvider = StateNotifierProvider<FocusStateNotifier, FocusState>((ref) {
  final stateService = ref.watch(stateServiceProvider);
  return FocusStateNotifier(stateService);
});