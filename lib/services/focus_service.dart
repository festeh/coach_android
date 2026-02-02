import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import '../constants/channel_names.dart';

final _log = Logger('FocusService');

class FocusService {
  static const MethodChannel _methodChannel = MethodChannel(ChannelNames.mainMethods);

  /// Opens the Android Usage Access Settings screen for the user to grant permission.
  ///
  /// Returns `true` if the settings screen was successfully launched,
  /// `false` otherwise. Throws a [PlatformException] if the native call fails.
  static Future<bool> requestUsageStatsPermission() async {
    try {
      _log.info('Requesting Usage Stats permission via native method...');
      final result = await _methodChannel.invokeMethod<bool>(
        'requestUsageStatsPermission',
      );
      _log.info('Native requestUsageStatsPermission call result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to request Usage Stats permission: ${e.message}', e);
      rethrow;
    } catch (e) {
      _log.severe('Unknown error requesting Usage Stats permission: $e');
      return false;
    }
  }

  /// Checks if the app has permission to access usage stats.
  static Future<bool> checkUsageStatsPermission() async {
    try {
      final bool? hasPermission = await _methodChannel.invokeMethod<bool>(
        'checkUsageStatsPermission',
      );
      _log.info('Native checkUsageStatsPermission call result: $hasPermission');
      return hasPermission ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to check usage stats permission: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error checking usage stats permission: $e');
      return false;
    }
  }

  /// Checks if the app has permission to draw system overlays.
  static Future<bool> checkOverlayPermission() async {
    try {
      final bool? hasPermission = await _methodChannel.invokeMethod<bool>(
        'checkOverlayPermission',
      );
      _log.info('Native checkOverlayPermission call result: $hasPermission');
      return hasPermission ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to check overlay permission: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error checking overlay permission: $e');
      return false;
    }
  }

  /// Opens the Android settings screen for the user to grant overlay permission.
  ///
  /// Returns `true` if the settings screen was successfully launched,
  /// `false` otherwise. Throws a [PlatformException] if the native call fails.
  static Future<bool> requestOverlayPermission() async {
    try {
      _log.info('Requesting Overlay permission via native method...');
      final result = await _methodChannel.invokeMethod<bool>(
        'requestOverlayPermission',
      );
      _log.info('Native requestOverlayPermission call result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to request Overlay permission: ${e.message}', e);
      rethrow;
    } catch (e) {
      _log.severe('Unknown error requesting Overlay permission: $e');
      return false;
    }
  }

  /// Shows the native system overlay, displaying the provided [packageName].
  ///
  /// Requires Android Oreo (API 26) or higher and overlay permission.
  static Future<void> showOverlay(String packageName, {String? overlayType}) async {
    try {
      _log.info(
        'Requesting to show native overlay for package: $packageName (type: ${overlayType ?? 'coach'})...',
      );
      await _methodChannel.invokeMethod('showOverlay', {
        'packageName': packageName,
        if (overlayType != null) 'overlayType': overlayType,
      });
      _log.info('Native showOverlay call successful for $packageName.');
    } on PlatformException catch (e) {
      _log.severe('Failed to show overlay for $packageName: ${e.message}', e);
      // Handle specific errors like UNSUPPORTED_OS if needed
    } catch (e) {
      _log.severe('Unknown error showing overlay: $e');
    }
  }

  /// Hides the native system overlay if it's currently shown.
  static Future<void> hideOverlay() async {
    try {
      _log.info('Requesting to hide native overlay...');
      await _methodChannel.invokeMethod('hideOverlay');
      _log.info('Native hideOverlay call successful.');
    } on PlatformException catch (e) {
      _log.severe('Failed to hide overlay: ${e.message}', e);
    } catch (e) {
      _log.severe('Unknown error hiding overlay: $e');
    }
  }

  /// Starts the focus monitor background service.
  static Future<bool> startFocusMonitorService() async {
    try {
      _log.info('Starting focus monitor service...');
      final result = await _methodChannel.invokeMethod<bool>(
        'startFocusMonitorService',
      );
      _log.info('Focus monitor service start result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to start focus monitor service: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error starting focus monitor service: $e');
      return false;
    }
  }

  /// Stops the focus monitor background service.
  static Future<bool> stopFocusMonitorService() async {
    try {
      _log.info('Stopping focus monitor service...');
      final result = await _methodChannel.invokeMethod<bool>(
        'stopFocusMonitorService',
      );
      _log.info('Focus monitor service stop result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to stop focus monitor service: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error stopping focus monitor service: $e');
      return false;
    }
  }

  /// Checks if the focus monitor service is running.
  static Future<bool> isServiceRunning() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isServiceRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to check if service is running: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error checking service status: $e');
      return false;
    }
  }

  /// Requests focus state refresh from background service.
  static Future<void> requestFocusStateRefresh() async {
    try {
      _log.info('Requesting focus state refresh...');
      await _methodChannel.invokeMethod('requestFocusStateRefresh');
      _log.info('Focus state refresh request sent.');
    } on PlatformException catch (e) {
      _log.severe('Failed to request focus state refresh: ${e.message}', e);
      rethrow;
    } catch (e) {
      _log.severe('Unknown error requesting focus state refresh: $e');
      rethrow;
    }
  }

  /// Checks if the app is excluded from battery optimization.
  static Future<bool> checkBatteryOptimizationExclusion() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>(
        'checkBatteryOptimizationExclusion',
      );
      _log.info('Battery optimization exclusion status: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to check battery optimization: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error checking battery optimization: $e');
      return false;
    }
  }

  /// Opens settings to request battery optimization exclusion.
  static Future<bool> requestBatteryOptimizationExclusion() async {
    try {
      _log.info('Requesting battery optimization exclusion...');
      final result = await _methodChannel.invokeMethod<bool>(
        'requestBatteryOptimizationExclusion',
      );
      _log.info('Battery optimization exclusion request result: $result');
      return result ?? false;
    } on PlatformException catch (e) {
      _log.severe('Failed to request battery optimization exclusion: ${e.message}', e);
      return false;
    } catch (e) {
      _log.severe('Unknown error requesting battery optimization exclusion: $e');
      return false;
    }
  }

  /// Gets app usage stats for a given day from Android's UsageStatsManager.
  static Future<List<AppUsageEntry>> getAppUsageStats(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getAppUsageStats',
        {
          'startTime': startOfDay.millisecondsSinceEpoch,
          'endTime': endOfDay.millisecondsSinceEpoch,
        },
      );

      if (result == null) return [];

      return result.map((item) {
        final map = item as Map<dynamic, dynamic>;
        return AppUsageEntry(
          packageName: map['packageName'] as String,
          totalTimeMs: map['totalTimeMs'] as int,
        );
      }).toList();
    } on PlatformException catch (e) {
      _log.severe('Failed to get app usage stats: ${e.message}', e);
      return [];
    } catch (e) {
      _log.severe('Unknown error getting app usage stats: $e');
      return [];
    }
  }
}

class AppUsageEntry {
  final String packageName;
  final int totalTimeMs;

  AppUsageEntry({
    required this.packageName,
    required this.totalTimeMs,
  });

  int get totalTimeSeconds => totalTimeMs ~/ 1000;

  String get formattedTime {
    final totalSeconds = totalTimeMs ~/ 1000;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return '<1m';
    }
  }
}