import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_app_monitor/foreground_app_monitor_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelForegroundAppMonitor platform = MethodChannelForegroundAppMonitor();
  const MethodChannel channel = MethodChannel('foreground_app_monitor');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
