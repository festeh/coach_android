import 'dart:async';
import 'dart:async';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state.dart';
import 'package:foreground_app_monitor/foreground_app_monitor.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
// Import the overlay window package
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

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

  // Listen to the stream provided by the plugin
  _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen(
    (String foregroundAppPackage) async {
      // Add async keyword here
      // Keep the core logic as requested
      _log.finer('Foreground app changed: $foregroundAppPackage');
      if (_monitoredPackages.contains(foregroundAppPackage)) {
        final logMessage = '$foregroundAppPackage opened!';
        _log.info(logMessage);
        PersistentLog.addLog(logMessage);
        _log.info('Showing focus overlay window for $foregroundAppPackage...');
        PersistentLog.addLog(
          'Showing focus overlay window for $foregroundAppPackage',
        );
        try {
          // Check if overlay is active before showing to avoid duplicates
          final bool isActive = await FlutterOverlayWindow.isActive();
          if (!isActive) {
            await FlutterOverlayWindow.showOverlay(
              // The actual UI is defined in overlayEntryPoint (lib/overlay.dart)
              // Optional parameters can be set here:
              height: 200, // Example height, adjust as needed
              width: 300, // Example width, adjust as needed
              alignment: OverlayAlignment.center,
              // flag: OverlayFlag.focusPointer, // Example flag
              enableDrag: false,
              overlayTitle: 'Focus Overlay',
              overlayContent: 'Focus on $foregroundAppPackage',
            );
            _log.info('Focus overlay window display requested.');
            PersistentLog.addLog('Focus overlay window display requested.');
          } else {
            _log.info('Overlay window is already active.');
            PersistentLog.addLog(
              'Overlay window already active, not showing again.',
            );
          }
        } catch (e) {
          _log.severe('Error showing overlay window: $e');
          PersistentLog.addLog('Error showing overlay window: $e');
          // Check if it's a permission error (basic string check)
          if (e.toString().contains('PERMISSION') ||
              e.toString().contains('Permission')) {
            _log.warning(
              'Overlay permission might be missing. Cannot show overlay.',
            );
            PersistentLog.addLog('Overlay permission might be missing.');
            // Consider notifying the main UI or attempting to request permission again
            // await FlutterOverlayWindow.requestPermission(); // Example, might need better placement
          }
        }
        // --- End Overlay Window ---
      }
    },
    onError: (error) {
      // Handle errors, including potential PlatformExceptions for permissions
      if (error is PlatformException && error.code == 'PERMISSION_DENIED') {
        final logMessage =
            'Permission denied for usage stats. Monitoring stopped.';
        _log.severe(logMessage);
        PersistentLog.addLog(logMessage);
        // Request permission from the user
        _log.info('Attempting to request Usage Stats permission from user...');
        ForegroundAppMonitor.requestUsageStatsPermission()
            .then((opened) {
              if (opened) {
                _log.info('Usage Access Settings screen opened successfully.');
              } else {
                _log.warning('Could not open Usage Access Settings screen.');
              }
            })
            .catchError((e) {
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

  _log.info(
    'App monitoring setup complete. Listening for foreground app changes.',
  );
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
