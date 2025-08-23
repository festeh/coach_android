import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'app.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging to print to console
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  
  // WebSocket service initialization is now handled by the background isolate
  // Background service initialization is now handled by the app monitor
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
