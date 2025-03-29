import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'foreground_app_monitor_method_channel.dart';

abstract class ForegroundAppMonitorPlatform extends PlatformInterface {
  /// Constructs a ForegroundAppMonitorPlatform.
  ForegroundAppMonitorPlatform() : super(token: _token);

  static final Object _token = Object();

  static ForegroundAppMonitorPlatform _instance = MethodChannelForegroundAppMonitor();

  /// The default instance of [ForegroundAppMonitorPlatform] to use.
  ///
  /// Defaults to [MethodChannelForegroundAppMonitor].
  static ForegroundAppMonitorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ForegroundAppMonitorPlatform] when
  /// they register themselves.
  static set instance(ForegroundAppMonitorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
