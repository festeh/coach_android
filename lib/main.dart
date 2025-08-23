import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import 'app.dart';

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
