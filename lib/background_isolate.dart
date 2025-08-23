import 'package:coach_android/background_monitor_handler.dart';
import 'package:coach_android/services/websocket_service.dart';
import 'package:logging/logging.dart';

final _log = Logger('BackgroundIsolate');

/// This is the entry point for the background Flutter isolate
/// It runs independently of the main UI and handles all monitoring logic
@pragma('vm:entry-point')
void backgroundMain() {
  _log.info('Background isolate started');
  
  // Initialize the background monitor handler (which will initialize WebSocket)
  BackgroundMonitorHandler.initialize();
}

/// Callback for when the background isolate is initialized
@pragma('vm:entry-point')
void backgroundCallback() {
  _log.info('Background callback invoked');
  backgroundMain();
}