import 'dart:async';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state_management/services/state_service.dart';
import 'package:foreground_app_monitor/foreground_app_monitor.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppMonitor');

StreamSubscription<String>? _foregroundAppSubscription;

// Set to hold the package names of apps we are monitoring
Set<String> _monitoredPackages = {};

Future<void> startAppMonitoring([BuildContext? context]) async {
  _log.info('Initializing app monitoring...');

  // Load monitored packages using StateService
  final stateService = StateService();
  _monitoredPackages = await stateService.loadSelectedAppPackages();
  _log.info('Monitoring for apps: ${_monitoredPackages.join(', ')}');

  await _foregroundAppSubscription?.cancel(); // Cancel previous subscription if any

  _log.info('Initializing ForegroundAppMonitor...');
  ForegroundAppMonitor.initialize();

  // Check for overlay permission before starting
  bool hasOverlayPerm = await ForegroundAppMonitor.checkOverlayPermission();
  if (!hasOverlayPerm) {
    _log.warning('Overlay permission not granted. Overlay will not be shown.');
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
  _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen((packageName) {
    _log.fine('Foreground app: $packageName');
    
    if (_monitoredPackages.contains(packageName)) {
      _log.info('Detected monitored app: $packageName');
      PersistentLog.addLog('Opened monitored app: $packageName');
      ForegroundAppMonitor.showOverlay('Focus Time!'); // Show overlay when monitored app is opened
    } else {
      ForegroundAppMonitor.hideOverlay(); // Hide overlay for non-monitored apps
    }
  });

  _log.info('App monitoring started successfully.');
  PersistentLog.addLog('App monitoring started.');
}

void stopAppMonitoring() {
  _log.info('Stopping app monitoring...');
  _foregroundAppSubscription?.cancel();
  _foregroundAppSubscription = null;
  ForegroundAppMonitor.hideOverlay(); // Ensure overlay is hidden
  _log.info('App monitoring stopped.');
  PersistentLog.addLog('App monitoring stopped.');
}

Future<void> updateMonitoredApps(Set<String> packages) async {
  _monitoredPackages = packages;
  _log.info('Updated monitored apps: ${packages.length} apps');
  
  // Save to persistence
  final stateService = StateService();
  await stateService.saveSelectedApps(packages);
}

Future<bool> checkAndRequestUsageStatsPermission(BuildContext context) async {
  bool hasPermission = await ForegroundAppMonitor.checkUsageStatsPermission();
  
  if (!hasPermission && context.mounted) {
    // Show dialog to request permission
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Usage Stats Permission Required'),
          content: const Text(
            'This app needs Usage Stats permission to monitor app usage and help you focus. '
            'You will be redirected to Settings to enable this permission.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Grant Permission'),
            ),
          ],
        );
      },
    );
    
    if (shouldRequest == true) {
      await ForegroundAppMonitor.requestUsageStatsPermission();
      // Check again after user returns from settings
      hasPermission = await ForegroundAppMonitor.checkUsageStatsPermission();
    }
  }
  
  return hasPermission;
}