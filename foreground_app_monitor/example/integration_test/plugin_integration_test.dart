// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing


import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:foreground_app_monitor/foreground_app_monitor.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('foreground app monitoring test', (WidgetTester tester) async {
    // Initialize the plugin
    ForegroundAppMonitor.initialize();
    
    // Test that the stream is available
    expect(ForegroundAppMonitor.foregroundAppStream, isA<Stream<String>>());
    
    // Clean up
    ForegroundAppMonitor.dispose();
  });
}
