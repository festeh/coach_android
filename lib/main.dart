import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'dart:async';
import 'dart:ui';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBgService();
  runApp(const MyApp());
}

Future<void> initBgService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for persistent notifications
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'coach_channel', // id
    'Coach Notifications', // name
    description: 'Notifications from Coach app', // description
    importance: Importance.high,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()!
      .createNotificationChannel(channel);

  service.configure(
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      isForegroundMode: true,
      onStart: onStart,
      initialNotificationTitle: 'Coach',
      initialNotificationContent: 'Focus',
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
      notificationChannelId: 'coach_channel',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Import required packages
  // DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "Coach",
        content: "Time to focus",
      );
    }
  });

  return true;
}
