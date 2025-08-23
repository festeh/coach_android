import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('ForegroundAppMonitor');

class ForegroundAppMonitor {
  static const EventChannel _eventChannel = EventChannel(
    'com.example.foreground_app_monitor/foregroundApp',
  );
  static const MethodChannel _methodChannel = MethodChannel(
    'com.example.foreground_app_monitor/methods',
  );

  static StreamSubscription<dynamic>? _platformSubscription;
  static final StreamController<String> _foregroundAppController =
      StreamController<String>.broadcast();

  static bool _isInitialized = false;

  static void initialize() {
    if (_isInitialized) {
      _log.fine('Already initialized.');
      return;
    }
    _log.info('Initializing app monitor plugin...');
    
    // Initialize foreground app monitoring stream
    _platformSubscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        if (event is String) {
          _foregroundAppController.add(event);
        } else {
          _log.warning('Received non-String event: $event');
          _foregroundAppController.addError(
            FormatException('Received non-String event', event),
          );
        }
      },
      onError: (dynamic error) {
        _log.severe('Error from platform stream: $error');
        if (error is PlatformException) {
          _foregroundAppController.addError(error);
          if (error.code == 'PERMISSION_DENIED') {
            _log.warning('Usage stats permission required.');
          }
        } else {
          _foregroundAppController.addError(
            Exception('Unknown error from platform stream: $error'),
          );
        }
      },
      onDone: () {
        _log.info('Platform stream closed.');
        _isInitialized = false; // Allow re-initialization
      },
      cancelOnError: false, // Continue listening after errors
    );
    
    _isInitialized = true;
    _log.info('Initialization complete. Listening to platform stream.');
  }

  static Stream<String> get foregroundAppStream =>
      _foregroundAppController.stream;

  static void dispose() {
    _log.info('Disposing...');
    _platformSubscription?.cancel();
    _platformSubscription = null;
    // Don't close the broadcast controller if it might be used again
    // _foregroundAppController.close();
    _isInitialized = false;
    _log.info('Disposed.');
  }

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
      // Rethrow or handle as needed
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

  /// Starts the simple focus monitor background service.
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
}
