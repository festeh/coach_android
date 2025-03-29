import 'dart:async';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppMonitor');

const EventChannel _foregroundAppChannel =
    EventChannel('com.example.coach_android/foregroundApp');

StreamSubscription<dynamic>? _foregroundAppSubscription;

// Set to hold the package names of apps we are monitoring
Set<String> _monitoredPackages = {};

Future<void> startAppMonitoring() async {
  _log.info('Initializing app monitoring...');

  _monitoredPackages = await AppState.loadSelectedAppPackages();
  _log.info('Monitoring for apps: ${_monitoredPackages.join(', ')}');

  await _foregroundAppSubscription?.cancel();

  _foregroundAppSubscription =
      _foregroundAppChannel.receiveBroadcastStream().listen(
    (dynamic foregroundAppPackage) {
      if (foregroundAppPackage is String && foregroundAppPackage.isNotEmpty) {
        _log.finer('Foreground app changed: $foregroundAppPackage');
        if (_monitoredPackages.contains(foregroundAppPackage)) {
          final logMessage = '$foregroundAppPackage opened!';
          _log.info(logMessage);
          PersistentLog.addLog(logMessage);
          // TODO: Trigger desired action (e.g., notification, blocking)
        }
      } else {
        _log.warning(
          'Received unexpected data type from foregroundAppChannel: ${foregroundAppPackage.runtimeType}',
        );
      }
    },
    onError: (dynamic error) {
      _log.severe('Error receiving foreground app updates: $error');
      PersistentLog.addLog('Error in foreground app stream: $error');
    },
    onDone: () {
      _log.info('Foreground app stream closed.');
      PersistentLog.addLog('Foreground app stream closed.');
    },
    cancelOnError: false, // Keep listening even after errors if desired
  );

  _log.info('App monitoring setup complete. Listening for foreground app changes.');
  await PersistentLog.addLog('App monitoring setup complete.');
}

// Function to stop monitoring
void stopAppMonitoring() {
  _log.info('Stopping app monitoring...');
  PersistentLog.addLog('Stopping app monitoring...');
  // Cancel the stream subscription
  _foregroundAppSubscription?.cancel();
  _foregroundAppSubscription = null; // Clear the subscription reference
  _log.info('App monitoring stopped.');
  PersistentLog.addLog('App monitoring stopped.');
}
