import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'app.dart';
import 'bg.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging to print to console
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });
  
  await initBgService();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
