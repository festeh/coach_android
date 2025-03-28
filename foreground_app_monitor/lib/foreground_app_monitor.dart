import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _log = Logger('ForegroundAppMonitor');

class ForegroundAppMonitor {
  static const EventChannel _eventChannel =
      EventChannel('com.example.foreground_app_monitor/foregroundApp');
  // Add MethodChannel corresponding to the native side
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.foreground_app_monitor/methods');

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
      final result = await _methodChannel.invokeMethod<bool>('requestUsageStatsPermission');
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
}
