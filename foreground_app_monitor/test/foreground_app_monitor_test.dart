import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_app_monitor/foreground_app_monitor_platform_interface.dart';
import 'package:foreground_app_monitor/foreground_app_monitor_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockForegroundAppMonitorPlatform
    with MockPlatformInterfaceMixin
    implements ForegroundAppMonitorPlatform {

  // Implement the new stream getter in the mock
  @override
  Stream<String> get foregroundAppStream => Stream.fromIterable(['com.example.app1', 'com.example.app2']);

  // getPlatformVersion is removed
  // @override
  // Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ForegroundAppMonitorPlatform initialPlatform = ForegroundAppMonitorPlatform.instance;

  test('$MethodChannelForegroundAppMonitor is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelForegroundAppMonitor>());
  });

  // Update the test name and logic
  test('foregroundAppStream', () async {
    // Use the plugin's static stream directly as per the new design
    // ForegroundAppMonitor foregroundAppMonitorPlugin = ForegroundAppMonitor();
    MockForegroundAppMonitorPlatform fakePlatform = MockForegroundAppMonitorPlatform();
    ForegroundAppMonitorPlatform.instance = fakePlatform;

    // Test the stream provided by the platform instance
    expectLater(
      ForegroundAppMonitorPlatform.instance.foregroundAppStream,
      emitsInOrder(<String>['com.example.app1', 'com.example.app2']),
    );
  });
}
