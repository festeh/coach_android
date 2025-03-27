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
Timer? _reconnectTimer; // Timer for delayed reconnection

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
  _reconnectTimer?.cancel(); // Cancel any pending reconnection attempt
  _reconnectTimer = null;
  _channelSubscription?.cancel();
  _channelSubscription = null;
  _channel?.sink.close();
  _channel = null;
  _log.info('WebSocket connection closed.');
}

// Function to attempt WebSocket connection
void _connectWebSocket(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  AndroidNotificationDetails androidDetails,
) {
  if (_channel != null || _reconnectTimer != null) {
    _log.fine(
      'Skipping connection attempt (already connected or reconnect scheduled).',
    );
    return;
  }

  if (AppConfig.webSocketUrl.isEmpty) {
    _log.warning('WebSocket URL not available. Cannot connect.');
    return;
  }

  _log.info('Attempting to connect to WebSocket: ${AppConfig.webSocketUrl}');
  _channel = IOWebSocketChannel.connect(Uri.parse(AppConfig.webSocketUrl));
  _log.info('WebSocket connection established.');

  _channelSubscription = _channel!.stream.listen(
    (message) {
      _log.info('WebSocket message received: $message');
      notificationsPlugin.show(
        888, // Same notification ID
        'Coach', // Title
        message.toString(), // Body is the received message
        NotificationDetails(android: androidDetails), // Use existing details
      );
    },
    onError: (error) {
      _log.severe('WebSocket error: $error');
      // Update notification to show error state? (Optional)
      notificationsPlugin.show(
        888,
        'Coach',
        'Connection Error', // Indicate error in notification
        NotificationDetails(android: androidDetails),
      );
      _closeWebSocket();
      _scheduleReconnect(notificationsPlugin, androidDetails);
    },
    onDone: () {
      _log.info('WebSocket connection closed by server.');
      _scheduleReconnect(notificationsPlugin, androidDetails); // Pass args
    },
    cancelOnError: true, // Keep true to ensure cleanup on error
  );
}

// Schedules a single reconnection attempt after a delay
void _scheduleReconnect(
  FlutterLocalNotificationsPlugin notificationsPlugin,
  AndroidNotificationDetails androidDetails,
) {
  if (_reconnectTimer != null) {
    _log.fine('Reconnection already scheduled.');
    return; // Already scheduled
  }
  const reconnectDelay = Duration(seconds: 5);
  _log.info(
    'Scheduling WebSocket reconnection in ${reconnectDelay.inSeconds} seconds.',
  );
  _reconnectTimer = Timer(reconnectDelay, () {
    _reconnectTimer = null; // Clear the timer
    _connectWebSocket(notificationsPlugin, androidDetails);
  });
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
    print(
      '${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}',
    );
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
      _log.info('Background service is still running.');
    }
  });

  // Initial WebSocket connection attempt, passing notification objects
  _connectWebSocket(notificationsPlugin, androidDetails);

  return true; // Indicate that the service started successfully
}
