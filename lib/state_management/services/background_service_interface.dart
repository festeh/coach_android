import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'dart:async';
import '../providers/focus_provider.dart';
import '../providers/app_selection_provider.dart';

final _log = Logger('BackgroundServiceInterface');

class BackgroundServiceInterface {
  static StreamSubscription<Map<String, dynamic>?>? _focusingStateSubscription;
  static WidgetRef? _ref;

  static void initialize(WidgetRef ref) {
    _ref = ref;
    _setupListeners();
  }

  static void _setupListeners() {
    if (_ref == null) {
      _log.warning('WidgetRef not initialized');
      return;
    }

    // Cancel existing subscription if any
    _focusingStateSubscription?.cancel();

    // Listen for focus state updates from background service
    _focusingStateSubscription = FlutterBackgroundService()
        .on('updateFocusingState')
        .listen((event) {
          if (event != null && _ref != null) {
            _log.info('Received focusing update from background: $event');
            _ref!.read(focusStateProvider.notifier).updateFromWebSocket(event);
          }
        });

    // Listen for app selection updates
    FlutterBackgroundService().on('requestAppSelection').listen((event) {
      if (_ref != null) {
        final selectedPackages = _ref!.read(selectedPackagesProvider);
        _log.info('Sending app selection to background: ${selectedPackages.length} apps');
        FlutterBackgroundService().invoke(
          'updateAppSelection',
          {'packages': selectedPackages.toList()},
        );
      }
    });
  }

  static void sendFocusStateToBackground(bool isFocusing) {
    _log.info('Sending focus state to background: $isFocusing');
    FlutterBackgroundService().invoke(
      'updateFocusFromUI',
      {'isFocusing': isFocusing},
    );
  }

  static void sendAppSelectionToBackground(Set<String> packages) {
    _log.info('Sending app selection to background: ${packages.length} apps');
    FlutterBackgroundService().invoke(
      'updateAppSelection',
      {'packages': packages.toList()},
    );
  }

  static void dispose() {
    _focusingStateSubscription?.cancel();
    _focusingStateSubscription = null;
    _ref = null;
  }
}

// Provider to manage the background service interface
// Note: This needs to be initialized from a Widget context, not directly in a provider
class BackgroundServiceManager {
  static void initializeForWidget(WidgetRef ref) {
    BackgroundServiceInterface.initialize(ref);
  }
  
  static void dispose() {
    BackgroundServiceInterface.dispose();
  }
}