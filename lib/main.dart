import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'app.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBgService();
  runApp(const MyApp());
}

Future<void> initBgService() async {
  final service = FlutterBackgroundService();

  service.configure(
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      isForegroundMode: true,
      onStart: onStart,
      initialNotificationTitle: 'Coach',
      initialNotificationContent: 'Focus',
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Import required packages
  // DartPluginRegistrant.ensureInitialized();

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    // This keeps the service alive
    service.invoke('update', {
      "current_date": DateTime.now().toIso8601String(),
    });
    print('Service is still running');
  });
  return true;
}
