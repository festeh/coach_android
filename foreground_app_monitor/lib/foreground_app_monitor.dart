
import 'foreground_app_monitor_platform_interface.dart';

class ForegroundAppMonitor {
  Future<String?> getPlatformVersion() {
    return ForegroundAppMonitorPlatform.instance.getPlatformVersion();
  }
}
