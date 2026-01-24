import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'app.dart';
import 'background_monitor_handler.dart';
import 'services/focus_service.dart';
import 'services/installed_apps_service.dart';

final _log = Logger('Main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging to print to console
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  
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
void backgroundMain() {
  final log = Logger('BackgroundIsolate');

  try {
    // Configure logging for background isolate to output to Android logcat
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Use print() to ensure logs appear in Android logcat
      // ignore: avoid_print
      print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });

    log.info('Background isolate entry point called');

    WidgetsFlutterBinding.ensureInitialized();
    log.info('Flutter binding initialized');

    log.info('Background isolate started');

    // Initialize the background monitor handler (which will initialize WebSocket)
    BackgroundMonitorHandler.initialize();
    log.info('BackgroundMonitorHandler.initialize() called');
  } catch (e, stackTrace) {
    log.severe('Failed to start background isolate: $e', e, stackTrace);
    // Re-throw so the native side can handle the error
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
