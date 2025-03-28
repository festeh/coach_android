import 'package:coach_android/app_monitor.dart';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/websocket.dart';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

final _log = Logger('BackgroundService');

// Ensure Dart isolate entry point is available
@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  // This function needs to exist but might remain empty or used for specific background tasks
  // unrelated to the main service logic if `onStart` handles everything.
  // Or, it could be the entry point for certain callbacks if configured differently.
}

const int notificationId = 888;

Future<void> initBgService() async {
  final service = FlutterBackgroundService();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'coach_channel', // id
    'Coach Notifications', // name
    description: 'Notifications from Coach app',
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
      notificationChannelId: 'coach_channel',
      foregroundServiceNotificationId: notificationId,
    ),
    iosConfiguration: IosConfiguration(autoStart: true),
  );
}

Future<AndroidNotificationDetails> showNotification(
  FlutterLocalNotificationsPlugin notificationsPlugin,
) async {
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'coach_channel',
    'Coach Notifications',
    importance: Importance.max,
    priority: Priority.high,
    ongoing: true,
    onlyAlertOnce: true,
    icon: 'ic_bg_service_small',
  );

  await notificationsPlugin.show(
    notificationId,
    'Coach',
    'Time to Focus',
    NotificationDetails(android: androidDetails),
  );
  return androidDetails;
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // IMPORTANT: Register the Dart isolate entry point for background execution
  DartPluginRegistrant.ensureInitialized();

  // Setup logging listener for the background isolate
  Logger.root.level = Level.ALL; // Log all levels
  Logger.root.onRecord.listen((record) {
    // Log to persistent storage as well
    PersistentLog.addLog(
      'BG L:${record.level.name} T:${record.time} N:${record.loggerName} M:${record.message}',
    );
    // Keep console print for debugging if attached
    // ignore: avoid_print
    print(
      'BG ${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
  });

  _log.info("Background service starting...");
  await PersistentLog.addLog("Background service starting...");

  service.on('stopService').listen((event) async {
    _log.info('stopService event received.');
    await PersistentLog.addLog('stopService event received.');
    closeWebSocket(); // Close WebSocket connection
    stopAppMonitoring(); // Stop app monitoring
    service.stopSelf(); // Stop the background service
    _log.info('Background service stopped.');
    await PersistentLog.addLog('Background service stopped.');
  });
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationDetails androidDetails = await showNotification(
    notificationsPlugin,
  );

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      _log.info('Background service is still running.');
    }
  });

  // Start app monitoring
  await startAppMonitoring();

  connectWebSocket(notificationsPlugin, androidDetails, notificationId);

  _log.info("Background service started successfully.");
  await PersistentLog.addLog("Background service started successfully.");
  return true; // Indicate that the service started successfully
}
