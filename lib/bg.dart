import 'package:coach_android/config.dart'; // Import AppConfig
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web_socket_channel/io.dart'; // Import IOWebSocketChannel
import 'package:web_socket_channel/web_socket_channel.dart'; // Import base WebSocketChannel

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
  print('WebSocket connection closed.');
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
  // --- Service Stop Listener ---
  // Ensure this is registered early to handle stop commands correctly.
  service.on('stopService').listen((event) {
    print('Background Service: stopService event received.');
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
    print(
      'Background Service: WebSocket URL not available. Skipping connection.',
    );
    return false;
  }

  print(
    'Background Service: Connecting to WebSocket: ${AppConfig.webSocketUrl}',
  );
  try {
    _channel = IOWebSocketChannel.connect(Uri.parse(AppConfig.webSocketUrl));

    _channelSubscription = _channel!.stream.listen(
      (message) {
        // Handle incoming WebSocket messages
        print('Background Service: WebSocket message received: $message');
        // You might want to process the message or invoke methods on the UI thread
        // service.invoke('messageFromBackground', {'data': message});
      },
      onError: (error) {
        print('Background Service: WebSocket error: $error');
        // Handle errors, maybe attempt to reconnect after a delay
        _closeWebSocket(); // Close on error for now
        // TODO: Implement reconnection logic if needed
      },
      onDone: () {
        print('Background Service: WebSocket connection closed by server.');
        _closeWebSocket();
        // TODO: Implement reconnection logic if needed
      },
      cancelOnError: true, // Close subscription on error
    );

    print('Background Service: WebSocket connection established.');
    // Optionally send an initial message or identifier
    // _channel?.sink.add('Hello from background service!');
  } catch (e) {
    print('Background Service: Failed to connect to WebSocket: $e');
    // Handle connection failure
  }

  return true; // Indicate that the service started successfully
}
