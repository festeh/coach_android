import 'dart:async';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state.dart';
import 'package:foreground_app_monitor/foreground_app_monitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppMonitor');

StreamSubscription<String>? _foregroundAppSubscription;

// Set to hold the package names of apps we are monitoring
Set<String> _monitoredPackages = {};

Future<void> startAppMonitoring([BuildContext? context]) async {
  _log.info('Initializing app monitoring...');

  _monitoredPackages = await AppState.loadSelectedAppPackages();
  _log.info('Monitoring for apps: ${_monitoredPackages.join(', ')}');

  await _foregroundAppSubscription
      ?.cancel(); // Cancel previous subscription if any

  _log.info('Initializing ForegroundAppMonitor...');
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

  // Verify usage stats permission
  bool hasUsageStatsPerm = await ForegroundAppMonitor.checkUsageStatsPermission();
  if (!hasUsageStatsPerm) {
    _log.severe('Usage Stats permission not granted. Monitoring will not work.');
    await PersistentLog.addLog('Usage Stats permission not granted. Monitoring will not work.');
    return;
  } else {
    _log.info('Usage Stats permission granted.');
  }

  // Listen to the stream provided by the plugin
  _log.info('Setting up foreground app stream listener...');
  _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen(
    (String foregroundAppPackage) async {
      _log.info('Foreground app changed: $foregroundAppPackage');
      final isFocusing = await AppState.loadFocusingState();
      if (_monitoredPackages.contains(foregroundAppPackage) && isFocusing) {
        _log.info(
          'Focusing state. Showing focus overlay window for $foregroundAppPackage...',
        );
        await ForegroundAppMonitor.showOverlay(foregroundAppPackage);
      } else {
        if (!isFocusing) {
          _log.info('Not in focusing state. Skipping...');
        } else {
          _log.info(
            'App ($foregroundAppPackage) not in monitored list. Hiding overlay.',
          );
        }
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
        
        // Show permission dialog if context is available
        if (context != null && context.mounted) {
          _showUsageStatsPermissionDialog(context);
        }
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

Future<void> checkAndRequestUsageStatsPermission(BuildContext context) async {
  try {
    _log.info('Checking Usage Stats permission...');
    final hasPermission = await ForegroundAppMonitor.checkUsageStatsPermission();
    
    if (!hasPermission) {
      _log.info('Usage Stats permission not granted, showing dialog...');
      if (context.mounted) {
        _showUsageStatsPermissionDialog(context);
      }
    } else {
      _log.info('Usage Stats permission already granted');
    }
  } catch (e) {
    _log.warning('Error checking Usage Stats permission: $e');
  }
}

void _showUsageStatsPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permission Required'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Coach needs access to Usage Stats to monitor which apps you\'re using.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              'This permission allows the app to detect when you open monitored apps and show focus reminders.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _log.info('User cancelled Usage Stats permission request');
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _log.info('User approved Usage Stats permission request');
              try {
                await ForegroundAppMonitor.requestUsageStatsPermission();
                await PersistentLog.addLog('Opened Usage Stats settings for user');
                
                // Show a snackbar to inform user what to do
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enable "Coach" in the Usage Access settings and return to the app'),
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              } catch (e) {
                _log.severe('Failed to open Usage Stats settings: $e');
                await PersistentLog.addLog('Failed to open Usage Stats settings: $e');
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      );
    },
  );
}
