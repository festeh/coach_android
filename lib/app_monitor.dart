import 'dart:async';
import 'dart:convert';
import 'package:coach_android/persistent_log.dart';
import 'package:coach_android/state_management/services/state_service.dart';
import 'package:foreground_app_monitor/foreground_app_monitor.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('AppMonitor');

StreamSubscription<String>? _foregroundAppSubscription;

// Set to hold the package names of apps we are monitoring
Set<String> _monitoredPackages = {};

// Focus state - to be updated by the focus provider
bool _isFocusing = false;

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

  try {
    // Start the native background service
    final serviceStarted = await ForegroundAppMonitor.startFocusMonitorService();
    if (!serviceStarted) {
      throw Exception('Failed to start native service');
    }

    // Listen to the stream provided by the native service
    _log.info('Setting up foreground app stream listener...');
    _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen((packageName) {
      _log.fine('Foreground app: $packageName');
      
      // This is where Flutter makes the decision about overlay
      if (_shouldShowOverlay(packageName)) {
        _log.info('Should show overlay for app: $packageName');
        PersistentLog.addLog('Blocked app opened during focus: $packageName');
        ForegroundAppMonitor.showOverlay(packageName); // Show overlay
      } else {
        ForegroundAppMonitor.hideOverlay(); // Hide overlay for non-blocked apps
      }
    });

    _log.info('App monitoring started successfully.');
    await PersistentLog.addLog('App monitoring started.');
    
    // Sync current state to background isolate
    await _syncFocusStateToBackground(_isFocusing);
    await _syncMonitoredAppsToBackground(_monitoredPackages);
  } catch (e) {
    _log.severe('Failed to start monitoring service: $e');
    await PersistentLog.addLog('Failed to start monitoring service: $e');
    rethrow;
  }
}

// Helper function to determine if overlay should be shown
bool _shouldShowOverlay(String packageName) {
  // Check if app is in the blocked/monitored list AND we are currently focusing
  return _monitoredPackages.contains(packageName) && _isFocusing;
}

// Function to update focus state (called from focus provider)
void updateFocusState(bool focusing) async {
  _isFocusing = focusing;
  _log.info('Focus state updated: $_isFocusing');
  
  // Sync to SharedPreferences for background isolate
  await _syncFocusStateToBackground(focusing);
}

// Sync focus state to SharedPreferences for background isolate
Future<void> _syncFocusStateToBackground(bool focusing) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('background_focus_state', focusing);
    _log.info('Synced focus state to background: $focusing');
  } catch (e) {
    _log.severe('Failed to sync focus state to background: $e');
  }
}

Future<void> stopAppMonitoring() async {
  _log.info('Stopping app monitoring...');
  
  try {
    _foregroundAppSubscription?.cancel();
    _foregroundAppSubscription = null;
    
    await ForegroundAppMonitor.stopFocusMonitorService();
    ForegroundAppMonitor.hideOverlay(); // Ensure overlay is hidden
    
    _log.info('App monitoring stopped.');
    await PersistentLog.addLog('App monitoring stopped.');
  } catch (e) {
    _log.severe('Failed to stop monitoring service: $e');
    await PersistentLog.addLog('Failed to stop monitoring service: $e');
  }
}

Future<void> updateMonitoredApps(Set<String> packages) async {
  _monitoredPackages = packages;
  _log.info('Updated monitored apps: ${packages.length} apps');
  
  // Save to persistence
  final stateService = StateService();
  await stateService.saveSelectedApps(packages);
  
  // Sync to SharedPreferences for background isolate
  await _syncMonitoredAppsToBackground(packages);
}

// Sync monitored apps to SharedPreferences for background isolate
Future<void> _syncMonitoredAppsToBackground(Set<String> packages) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('background_monitored_apps', jsonEncode(packages.toList()));
    _log.info('Synced monitored apps to background: ${packages.length} apps');
  } catch (e) {
    _log.severe('Failed to sync monitored apps to background: $e');
  }
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