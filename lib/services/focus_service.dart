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
  static Future<void> showOverlay(String packageName) async {
    try {
      _log.info(
        'Requesting to show native overlay for package: $packageName...',
      );
      // Pass the package name as an argument
      await _methodChannel.invokeMethod('showOverlay', {
        'packageName': packageName,
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
}