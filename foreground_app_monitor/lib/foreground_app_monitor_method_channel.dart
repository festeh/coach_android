import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'foreground_app_monitor_platform_interface.dart';

/// An implementation of [ForegroundAppMonitorPlatform] that uses event channels
/// to receive foreground app updates from the native platform.
class MethodChannelForegroundAppMonitor extends ForegroundAppMonitorPlatform {
  /// The event channel used to receive foreground app updates from the native platform.
  /// The name must match the one used in the native code (Kotlin/Swift).
  @visibleForTesting
  final eventChannel = const EventChannel(
    'com.example.foreground_app_monitor/foregroundApp',
  );

  // Cache the stream to avoid creating multiple stream listeners unnecessarily.
  Stream<String>? _foregroundAppStream;

  /// Returns a broadcast stream that emits the package name of the foreground
  /// application whenever it changes on the native side.
  @override
  Stream<String> get foregroundAppStream {
    _foregroundAppStream ??= eventChannel.receiveBroadcastStream().map((event) {
      // Ensure the event received from the platform is a String.
      if (event is String) {
        return event;
      } else {
        // Handle cases where the event is not a String, perhaps log or throw.
        // For now, returning an empty string or throwing might be options.
        // Consider how errors should be propagated.
        print(
          'ForegroundAppMonitorMethodChannel: Received non-String event: $event',
        );
        // Returning a specific error string or throwing might be better.
        return 'error_invalid_event_type';
      }
    });
    return _foregroundAppStream!;
  }
}
