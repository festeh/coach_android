import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'foreground_app_monitor_platform_interface.dart';

/// An implementation of [ForegroundAppMonitorPlatform] that uses method channels.
class MethodChannelForegroundAppMonitor extends ForegroundAppMonitorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('foreground_app_monitor');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
