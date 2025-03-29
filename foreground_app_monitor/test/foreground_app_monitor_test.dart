import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_app_monitor/foreground_app_monitor.dart';
import 'package:foreground_app_monitor/foreground_app_monitor_platform_interface.dart';
import 'package:foreground_app_monitor/foreground_app_monitor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockForegroundAppMonitorPlatform
    with MockPlatformInterfaceMixin
    implements ForegroundAppMonitorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ForegroundAppMonitorPlatform initialPlatform = ForegroundAppMonitorPlatform.instance;

  test('$MethodChannelForegroundAppMonitor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelForegroundAppMonitor>());
  });

  test('getPlatformVersion', () async {
    ForegroundAppMonitor foregroundAppMonitorPlugin = ForegroundAppMonitor();
    MockForegroundAppMonitorPlatform fakePlatform = MockForegroundAppMonitorPlatform();
    ForegroundAppMonitorPlatform.instance = fakePlatform;

    expect(await foregroundAppMonitorPlugin.getPlatformVersion(), '42');
  });
}
