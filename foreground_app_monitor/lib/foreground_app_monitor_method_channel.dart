import 'dart:async';

import 'package:flutter/services.dart';

import 'foreground_app_monitor_platform_interface.dart';

class MethodChannelForegroundAppMonitor extends ForegroundAppMonitorPlatform {
  static const EventChannel _eventChannel = EventChannel(
    'com.example.foreground_app_monitor/foregroundApp',
  );

  static StreamSubscription<dynamic>? _platformSubscription;
  static final StreamController<String> _foregroundAppController =
      StreamController<String>.broadcast();

  static bool _isInitialized = false;

  @override
  Stream<String> get foregroundAppStream {
    if (!_isInitialized) {
      _initialize();
    }
    return _foregroundAppController.stream;
  }

  static void _initialize() {
    if (_isInitialized) {
      return;
    }

    _platformSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          _foregroundAppController.add(event);
        } else {
          _foregroundAppController.addError(
            FormatException('Received non-String event', event),
          );
        }
      },
      onError: (dynamic error) {
        if (error is PlatformException) {
          _foregroundAppController.addError(error);
        } else {
          _foregroundAppController.addError(
            Exception('Unknown error from platform stream: $error'),
          );
        }
      },
      onDone: () {
        _isInitialized = false;
      },
      cancelOnError: false,
    );
    _isInitialized = true;
  }

  static void dispose() {
    _platformSubscription?.cancel();
    _platformSubscription = null;
    _isInitialized = false;
  }
}