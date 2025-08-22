import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:logging/logging.dart';
import '../models/focus_state.dart';
import '../../models/log_entry.dart';
import '../../services/enhanced_logger.dart';
import '../services/state_service.dart';

final _log = Logger('FocusProvider');

class FocusStateNotifier extends StateNotifier<FocusState> {
  final StateService _stateService;

  FocusStateNotifier(this._stateService) : super(const FocusState()) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    state = state.copyWith(status: FocusStatus.loading);
    try {
      final isFocusing = await _stateService.loadFocusingState();
      if (isFocusing != null) {
        state = state.copyWith(
          isFocusing: isFocusing,
          status: FocusStatus.ready,
        );
      } else {
        state = state.copyWith(
          status: FocusStatus.error,
          errorMessage: 'No focusing state found',
        );
      }
    } catch (e) {
      _log.severe('Error loading focus state: $e');
      state = state.copyWith(
        status: FocusStatus.error,
        errorMessage: e.toString(),
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

    // Persist the focusing state
    await _stateService.saveFocusingState(isFocusing);
  }

  Future<void> forceFetch() async {
    _log.info('Force fetching focus state from WebSocket');
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.connection,
      'Requesting fresh focus status from WebSocket',
    );
    
    state = state.copyWith(status: FocusStatus.loading);
    
    // Request fresh data from the background service/WebSocket
    final service = FlutterBackgroundService();
    service.invoke('requestFocusStatus');
    
    // Also load from local storage as a fallback
    // Give WebSocket a moment to respond before falling back
    await Future.delayed(const Duration(milliseconds: 500));
    
    // If still loading after WebSocket request, load from storage
    if (state.status == FocusStatus.loading) {
      EnhancedLogger.warning(
        LogSource.ui,
        LogCategory.connection,
        'No WebSocket response, loading from local storage',
      );
      await _loadInitialState();
    } else {
      EnhancedLogger.info(
        LogSource.ui,
        LogCategory.connection,
        'Focus status updated from WebSocket',
      );
    }
  }

  void updateFromWebSocket(Map<String, dynamic> data) {
    final focusing = data['focusing'] as bool? ?? false;
    final numFocuses = data['num_focuses'] as int? ?? 0;
    final timeLeft = (data['focus_time_left'] as int? ?? 0) / 60;
    
    EnhancedLogger.debug(
      LogSource.webSocket,
      LogCategory.connection,
      'Received focus update from WebSocket',
      {
        'focusing': focusing,
        'numFocuses': numFocuses,
        'timeLeft': timeLeft,
      },
    );
    
    updateFocusState(
      isFocusing: focusing,
      numFocuses: numFocuses,
      focusTimeLeft: timeLeft,
    );
  }
}

final stateServiceProvider = Provider<StateService>((ref) => StateService());

final focusStateProvider = StateNotifierProvider<FocusStateNotifier, FocusState>((ref) {
  final stateService = ref.watch(stateServiceProvider);
  return FocusStateNotifier(stateService);
});