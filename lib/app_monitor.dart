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

  await _foregroundAppSubscription
      ?.cancel(); // Cancel previous subscription if any

  ForegroundAppMonitor.initialize();

  // Check for overlay permission before starting
  bool hasOverlayPerm = await ForegroundAppMonitor.checkOverlayPermission();
  if (!hasOverlayPerm) {
    _log.warning('Overlay permission not granted. Overlay will not be shown.');
    // Optionally, trigger a request here or notify the user via the main UI
    // await ForegroundAppMonitor.requestOverlayPermission();
    await PersistentLog.addLog('Overlay permission not granted.');
  } else {
     _log.info('Overlay permission granted.');
  }


  // Listen to the stream provided by the plugin
  _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen(
    (String foregroundAppPackage) async {
      _log.finer('Foreground app changed: $foregroundAppPackage');
      bool hasOverlayPerm = await ForegroundAppMonitor.checkOverlayPermission(); // Re-check in case it changed
      if (_monitoredPackages.contains(foregroundAppPackage)) {
        _log.info('Monitored app in foreground: $foregroundAppPackage');
        if (hasOverlayPerm) {
           _log.info('Showing focus overlay window...');
           await ForegroundAppMonitor.showOverlay();
        } else {
            _log.warning('Cannot show overlay: Permission not granted.');
        }
      } else {
        _log.info('Monitored app in foreground: $foregroundAppPackage');
        if (hasOverlayPerm) {
           _log.info('Showing focus overlay window for $foregroundAppPackage...');
           // Pass the package name to showOverlay
           await ForegroundAppMonitor.showOverlay(foregroundAppPackage);
        } else {
            _log.warning('Cannot show overlay: Permission not granted.');
        }
      } else {
         _log.finer('App ($foregroundAppPackage) not in monitored list. Hiding overlay.');
         // Hide overlay if a non-monitored app comes to foreground
         await ForegroundAppMonitor.hideOverlay();
      }
    },
    onError: (error) {
      if (error is PlatformException && error.code == 'PERMISSION_DENIED') {
        final logMessage =
            'Permission denied for usage stats. Monitoring stopped.';
        _log.severe(logMessage);
        PersistentLog.addLog(logMessage);
        _log.info('Attempting to request Usage Stats permission from user...');
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

  _log.info(
    'App monitoring setup complete. Listening for foreground app changes.',
  );
  await PersistentLog.addLog('App monitoring setup complete.');
}

// Function to stop monitoring
Future<void> stopAppMonitoring() async {
  _log.info('Stopping app monitoring...');
  // Cancel the stream subscription
  _foregroundAppSubscription?.cancel();
  _foregroundAppSubscription = null; // Clear the subscription reference

  // Ensure overlay is hidden when monitoring stops
  await ForegroundAppMonitor.hideOverlay();

  _log.info('App monitoring stopped.');
  await PersistentLog.addLog('App monitoring stopped.');
}
