import 'dart:async';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state.dart';
import 'package:foreground_app_monitor/foreground_app_monitor.dart';
import 'package:flutter/services.dart'; 
import 'package:logging/logging.dart';

final _log = Logger('AppMonitor');

StreamSubscription<String>? _foregroundAppSubscription;

// Set to hold the package names of apps we are monitoring
Set<String> _monitoredPackages = {};

Future<void> startAppMonitoring() async {
  _log.info('Initializing app monitoring...');

  _monitoredPackages = await AppState.loadSelectedAppPackages();
  _log.info('Monitoring for apps: ${_monitoredPackages.join(', ')}');

  await _foregroundAppSubscription?.cancel(); // Cancel previous subscription if any

  ForegroundAppMonitor.initialize();

  // Listen to the stream provided by the plugin
  _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen(
    (String foregroundAppPackage) {
      // Keep the core logic as requested
      _log.finer('Foreground app changed: $foregroundAppPackage');
      if (_monitoredPackages.contains(foregroundAppPackage)) {
        final logMessage = '$foregroundAppPackage opened!';
        _log.info(logMessage);
        PersistentLog.addLog(logMessage);
        // TODO: Trigger desired action (e.g., notification, blocking)
      }
    },
    onError: (error) {
      // Handle errors, including potential PlatformExceptions for permissions
      if (error is PlatformException && error.code == 'PERMISSION_DENIED') {
        final logMessage = 'Permission denied for usage stats. Monitoring stopped.';
         _log.severe(logMessage);
         PersistentLog.addLog(logMessage);
         // Request permission from the user
         _log.info('Attempting to request Usage Stats permission from user...');
         ForegroundAppMonitor.requestUsageStatsPermission().then((opened) {
            if (opened) {
              _log.info('Usage Access Settings screen opened successfully.');
              // Monitoring is likely still stopped or failing, user needs to grant and potentially restart monitoring
            } else {
              _log.warning('Could not open Usage Access Settings screen.');
            }
         }).catchError((e) {
            _log.severe('Error trying to request usage stats permission: $e');
         });
         stopAppMonitoring(); // Stop monitoring until permission is granted and restarted
      } else {
         final logMessage = 'Error receiving foreground app updates: $error';
        _log.severe(logMessage);
        PersistentLog.addLog(logMessage);
      }
    },
    onDone: () {
      // This might not be called if the stream is managed externally
      // and never explicitly closed by the plugin unless the engine detaches.
      _log.info('Foreground app stream closed (onDone).');
    },
    cancelOnError: false, // Keep listening even after errors if desired
  );

  _log.info('App monitoring setup complete. Listening for foreground app changes.');
  await PersistentLog.addLog('App monitoring setup complete.');
}

// Function to stop monitoring
void stopAppMonitoring() {
  _log.info('Stopping app monitoring...');
  // Cancel the stream subscription
  _foregroundAppSubscription?.cancel();
  _foregroundAppSubscription = null; // Clear the subscription reference
  _log.info('App monitoring stopped.');
}
