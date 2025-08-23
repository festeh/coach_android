import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'background_monitor_handler.dart';

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
    const platform = MethodChannel('com.example.foreground_app_monitor/methods');
    await platform.invokeMethod('startService');
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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    final _backgroundLog = Logger('BackgroundIsolate');
    _backgroundLog.info('Background isolate started');

    // Initialize the background monitor handler (which will initialize WebSocket)
    BackgroundMonitorHandler.initialize();
  } catch (e, stackTrace) {
    final _backgroundLog = Logger('BackgroundIsolate');
    _backgroundLog.severe('Failed to start background isolate: $e', e, stackTrace);
    // Re-throw so the native side can handle the error
    rethrow;
  }
}

/// Callback for when the background isolate is initialized
@pragma('vm:entry-point')
void backgroundCallback() {
  final _backgroundLog = Logger('BackgroundIsolate');
  _backgroundLog.info('Background callback invoked');
  backgroundMain();
}
