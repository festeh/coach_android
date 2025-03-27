import 'package:coach_android/config.dart'; // Import AppConfig
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart'; // Import logging package
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// Logger instance for the background service
final _log = Logger('BackgroundService');

// Hold the WebSocket channel and subscription globally within the isolate's scope
WebSocketChannel? _channel;
StreamSubscription? _channelSubscription;

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

// Function to close the WebSocket connection
void _closeWebSocket() {
  _channelSubscription?.cancel();
  _channel?.sink.close();
  _channel = null;
  _channelSubscription = null;
  _log.info('WebSocket connection closed.');
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
    888,
    'Coach',
    'Time to Focus',
    NotificationDetails(android: androidDetails),
  );
  return androidDetails;
}

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Setup logging listener for the background isolate
  Logger.root.level = Level.ALL; // Log all levels
  Logger.root.onRecord.listen((record) {
    // Simple console output for background logs
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
  });

  _log.info("Background service starting...");

  service.on('stopService').listen((event) {
    _log.info('stopService event received.');
    _closeWebSocket(); // Close WebSocket connection
    service.stopSelf(); // Stop the background service
  });
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationDetails androidDetails = await showNotification(
    notificationsPlugin,
  );

  Timer.periodic(const Duration(seconds: 60), (timer) async {
    if (service is AndroidServiceInstance) {
      await notificationsPlugin.show(
        888,
        "Coach",
        'Time to Focus',
        NotificationDetails(android: androidDetails), // Reuse channel config
      );
    }
  });

  if (AppConfig.webSocketUrl.isEmpty) {
    _log.warning('WebSocket URL not available. Skipping connection.');
    return false; // Indicate service didn't fully start as expected
  }

  _log.info('Connecting to WebSocket: ${AppConfig.webSocketUrl}');
  try {
    _channel = IOWebSocketChannel.connect(Uri.parse(AppConfig.webSocketUrl));

    _channelSubscription = _channel!.stream.listen(
      (message) {
        _log.info('WebSocket message received: $message');
        // You might want to process the message or invoke methods on the UI thread
        // service.invoke('messageFromBackground', {'data': message});
      },
      onError: (error) {
        _log.severe('WebSocket error: $error');
        _closeWebSocket(); // Close on error for now
        // TODO: Implement reconnection logic if needed
      },
      onDone: () {
        _log.info('WebSocket connection closed by server.');
        _closeWebSocket();
        // TODO: Implement reconnection logic if needed
      },
      cancelOnError: true,
    );

    _log.info('WebSocket connection established.');
    // Optionally send an initial message or identifier
    // _channel?.sink.add('Hello from background service!');
  } catch (e) {
    _log.severe('Failed to connect to WebSocket: $e');
    // Handle connection failure
  }

  return true; // Indicate that the service started successfully
}
