import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'app.dart';
import 'background_monitor_handler.dart';
import 'services/enhanced_logger.dart';
import 'services/focus_service.dart';
import 'services/installed_apps_service.dart';

final _log = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging: bridge standard Logger → EnhancedLogger → logcat + in-app logs
  EnhancedLogger.initializeFromLogging();
  
  // Start background service early
  await _startBackgroundService();

  // Initialize installed apps service for app name lookup
  try {
    await InstalledAppsService.instance.init();
    _log.info('InstalledAppsService initialized');
  } catch (e) {
    _log.warning('Failed to initialize InstalledAppsService: $e');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

/// Start the background monitoring service
Future<void> _startBackgroundService() async {
  try {
    _log.info('Starting background service...');
    await FocusService.startFocusMonitorService();
    _log.info('Background service start command sent');
  } catch (e) {
    _log.severe('Failed to start background service: $e');
    // Continue anyway - service might already be running
  }
}

/// This is the entry point for the background Flutter isolate
/// It runs independently of the main UI and handles all monitoring logic
@pragma('vm:entry-point')
Future<void> backgroundMain() async {
  final log = Logger('BackgroundIsolate');

  try {
    // Configure logging: bridge standard Logger → EnhancedLogger → logcat + in-app logs
    EnhancedLogger.initializeFromLogging();

    log.info('Background isolate entry point called');

    WidgetsFlutterBinding.ensureInitialized();
    log.info('Flutter binding initialized');

    // Initialize the background monitor handler (which will initialize WebSocket)
    await BackgroundMonitorHandler.initialize();
    log.info('BackgroundMonitorHandler initialized');
  } catch (e, stackTrace) {
    log.severe('Failed to start background isolate: $e', e, stackTrace);
    rethrow;
  }
}

/// Callback for when the background isolate is initialized
@pragma('vm:entry-point')
void backgroundCallback() {
  final log = Logger('BackgroundIsolate');
  log.info('Background callback invoked');
  backgroundMain();
}
