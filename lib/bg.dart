import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<void> initBgService() async {
  final service = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
      foregroundServiceTypes: [AndroidForegroundType.specialUse],
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  service.on('stopService').listen((event) {
    print('stopService');
    service.stopSelf();
  });

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'coach_channel',
    'Coach Notifications',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    onlyAlertOnce: true,
    icon: 'ic_bg_service_small',
  );
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin.show(
    888,
    'Coach',
    'Time to Focus',
    NotificationDetails(android: androidDetails),
  );

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      await flutterLocalNotificationsPlugin.show(
        888,
        "Coach",
        'Time to Focus',
        NotificationDetails(android: androidDetails), // Reuse channel config
      );
    }
  });

  return true;
}
