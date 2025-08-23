import 'package:coach_android/services/enhanced_logger.dart';
import 'package:coach_android/models/log_entry.dart';
import 'package:coach_android/state_management/services/state_service.dart';
import 'package:coach_android/constants/storage_keys.dart';
import 'package:coach_android/background_monitor_handler.dart';
import 'package:coach_android/services/focus_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('AppMonitor');

// Removed stream subscription - now handled by background service

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

  // No longer need to cancel subscription - handled by background service

  // App monitoring is now handled by the background service

  // Check for overlay permission before starting
  bool hasOverlayPerm = await FocusService.checkOverlayPermission();
  if (!hasOverlayPerm) {
    _log.warning('Overlay permission not granted. Overlay will not be shown.');
    EnhancedLogger.warning(LogSource.system, LogCategory.system, 'Overlay permission not granted.');
  } else {
    _log.info('Overlay permission granted.');
  }

  // Verify usage stats permission
  bool hasUsageStatsPerm = await FocusService.checkUsageStatsPermission();
  if (!hasUsageStatsPerm) {
    _log.severe('Usage Stats permission not granted. Monitoring will not work.');
    EnhancedLogger.error(LogSource.system, LogCategory.system, 'Usage Stats permission not granted. Monitoring will not work.');
    return;
  } else {
    _log.info('Usage Stats permission granted.');
  }

  try {
    // Start the native background service - app change detection is now handled by the service
    final serviceStarted = await FocusService.startFocusMonitorService();
    if (!serviceStarted) {
      throw Exception('Failed to start native service');
    }

    _log.info('Background service started - app detection and overlay decisions now handled by background isolate');

    _log.info('App monitoring started successfully.');
    EnhancedLogger.info(LogSource.system, LogCategory.monitoring, 'App monitoring started.');
    
    // Sync current state to background isolate
    await _syncFocusStateToBackground(_isFocusing);
    // Sync monitored apps to background isolate immediately
    await BackgroundMonitorHandler.updateMonitoredPackages(_monitoredPackages);
  } catch (e) {
    _log.severe('Failed to start monitoring service: $e');
    EnhancedLogger.error(LogSource.system, LogCategory.monitoring, 'Failed to start monitoring service: $e');
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
    await prefs.setBool(StorageKeys.focusingState, focusing);
    _log.info('Synced focus state to background: $focusing');
  } catch (e) {
    _log.severe('Failed to sync focus state to background: $e');
  }
}

Future<void> stopAppMonitoring() async {
  _log.info('Stopping app monitoring...');
  
  try {
    await FocusService.stopFocusMonitorService();
    await FocusService.hideOverlay(); // Ensure overlay is hidden
    
    _log.info('App monitoring stopped.');
    EnhancedLogger.info(LogSource.system, LogCategory.monitoring, 'App monitoring stopped.');
  } catch (e) {
    _log.severe('Failed to stop monitoring service: $e');
    EnhancedLogger.error(LogSource.system, LogCategory.monitoring, 'Failed to stop monitoring service: $e');
  }
}

Future<void> updateMonitoredApps(Set<String> packages) async {
  _monitoredPackages = packages;
  _log.info('Updated monitored apps: ${packages.length} apps');
  
  // Save to persistence
  final stateService = StateService();
  await stateService.saveSelectedApps(packages);
  
  // Sync to background isolate immediately  
  await BackgroundMonitorHandler.updateMonitoredPackages(packages);
}

// Note: Removed _syncMonitoredAppsToBackground() - now using BackgroundMonitorHandler.updateMonitoredPackages() directly

Future<bool> checkAndRequestUsageStatsPermission(BuildContext context) async {
  bool hasPermission = await FocusService.checkUsageStatsPermission();
  
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
      await FocusService.requestUsageStatsPermission();
      // Check again after user returns from settings
      hasPermission = await FocusService.checkUsageStatsPermission();
    }
  }
  
  return hasPermission;
}