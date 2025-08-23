import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'foreground_app_monitor_method_channel.dart';

abstract class ForegroundAppMonitorPlatform extends PlatformInterface {
  ForegroundAppMonitorPlatform() : super(token: _token);

  static final Object _token = Object();

  static ForegroundAppMonitorPlatform _instance = MethodChannelForegroundAppMonitor();

  static ForegroundAppMonitorPlatform get instance => _instance;

  static set instance(ForegroundAppMonitorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Stream<String> get foregroundAppStream {
    throw UnimplementedError('foregroundAppStream has not been implemented.');
  }
}