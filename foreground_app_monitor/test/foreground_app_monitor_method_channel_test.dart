import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foreground_app_monitor/foreground_app_monitor_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Platform instance under test
  MethodChannelForegroundAppMonitor platform = MethodChannelForegroundAppMonitor();
  // Define the EventChannel matching the implementation
  const EventChannel channel =
      EventChannel('com.example.foreground_app_monitor/foregroundApp');

  // Stream controller to simulate native events
  StreamController<String>? controller;

  setUp(() {
    controller = StreamController<String>();
    // Use setMockStreamHandler for EventChannels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(channel, MockStreamHandler.inline(
      onListen: (arguments, sink) {
        // Pipe events from the controller to the sink the plugin listens to
        controller!.stream.listen((event) => sink.success(event),
            onError: (error) {
              if (error is PlatformException) {
                sink.error(code: error.code, message: error.message, details: error.details);
              } else {
                sink.error(code: 'ERROR', message: error.toString());
              }
            },
            onDone: () => sink.endOfStream());
      },
      onCancel: (arguments) {
        // Optional: Handle cancellation if needed
      },
    ));
  });

  tearDown(() {
    // Clean up the mock handler and controller
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(channel, null);
    controller?.close();
    controller = null;
  });

  // Update test name and logic for the stream
  test('foregroundAppStream emits events', () async {
    // Expect the platform's stream to emit the events added to the controller
    expectLater(
      platform.foregroundAppStream,
      emitsInOrder(<String>[
        'com.example.app1',
        'com.example.app2',
      ]),
    );

    // Simulate native side sending events
    controller?.add('com.example.app1');
    controller?.add('com.example.app2');
    await controller?.close(); // Close the stream to complete the expectation
  });

   test('foregroundAppStream emits errors', () async {
    // Expect the platform's stream to emit the error added to the controller
    expectLater(
      platform.foregroundAppStream,
      emitsError(isA<PlatformException>()
          .having((e) => e.code, 'code', 'PERMISSION_DENIED')),
    );

    // Simulate native side sending an error
    controller?.addError(PlatformException(code: 'PERMISSION_DENIED', message: 'Permission needed'));
    await controller?.close();
  });
}
