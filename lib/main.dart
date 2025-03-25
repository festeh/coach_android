import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app.dart';
import 'dart:async';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notifications
  await initNotifications();
  await initBgService();
  runApp(const MyApp());
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> initBgService() async {
  final service = FlutterBackgroundService();

  // Create notification channel for persistent notifications
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'coach_channel', // id
    'Coach Notifications', // name
    description: 'Notifications from Coach app', // description
    importance: Importance.low,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  service.configure(
    androidConfiguration: AndroidConfiguration(
      autoStart: true,
      isForegroundMode: true,
      onStart: onStart,
      initialNotificationTitle: 'Coach',
      initialNotificationContent: 'Focus',
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
      notificationChannelId: 'coach_channel',
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Import required packages
  // DartPluginRegistrant.ensureInitialized();

  // Show a persistent notification
  await showPersistentNotification();

  Timer.periodic(const Duration(minutes: 1), (timer) async {
    await showPersistentNotification();
  });

  Timer.periodic(const Duration(seconds: 5), (timer) async {
    print('Service is running');
  });

  return true;
}

@pragma('vm:entry-point')
Future<void> showPersistentNotification() async {
  final now = DateTime.now();
  final formattedTime = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'coach_channel',
        'Coach Notifications',
        channelDescription: 'Notifications from Coach app',
        importance: Importance.high,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
      );

  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
  );

  await flutterLocalNotificationsPlugin.show(
    42,
    'Coach is active',
    'Helping you focus since $formattedTime',
    platformChannelSpecifics,
  );
}
