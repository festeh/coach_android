import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
// Import the platform interface and method channel implementation if needed for direct access
// import 'package:foreground_app_monitor/foreground_app_monitor_platform_interface.dart';
// import 'package:foreground_app_monitor/foreground_app_monitor_method_channel.dart';

// Import the main plugin class which now likely exposes the stream directly or via platform interface
import 'package:foreground_app_monitor/foreground_app_monitor.dart';


void main() {
  // Ensure plugin bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the plugin listener (safe to call early)
  ForegroundAppMonitor.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // State variable to hold the latest foreground app package name
  String _foregroundApp = 'Unknown';
  // Subscription to the foreground app stream
  StreamSubscription<String>? _foregroundAppSubscription;
  // Optional: Store error messages
  String? _error;

  @override
  void initState() {
    super.initState();
    // Start listening to the foreground app stream
    listenToForegroundApp();
  }

  void listenToForegroundApp() {
    // Cancel any existing subscription
    _foregroundAppSubscription?.cancel();

    // Listen to the stream provided by the plugin
    _foregroundAppSubscription = ForegroundAppMonitor.foregroundAppStream.listen(
      (String packageName) {
        if (!mounted) return; // Check if the widget is still in the tree
        setState(() {
          _foregroundApp = packageName;
          _error = null; // Clear previous error on successful event
        });
        developer.log("Foreground App: $packageName"); // Log to console
      },
      onError: (error) {
        if (!mounted) return;
        developer.log("Error listening to foreground app stream: $error");
        String errorMessage = 'Failed to get foreground app.';
        if (error is PlatformException) {
          errorMessage = 'Error: ${error.message} (Code: ${error.code})';
           if (error.code == 'PERMISSION_DENIED') {
             errorMessage = 'Usage stats permission denied. Please grant access.';
             // TODO: Add button or guide to open settings
           }
        }
        setState(() {
          _error = errorMessage;
          _foregroundApp = 'Error'; // Update UI to show error state
        });
      },
      onDone: () {
        if (!mounted) return;
        developer.log("Foreground app stream closed.");
        setState(() {
          _foregroundApp = 'Stream closed';
        });
      },
    );
     developer.log("Started listening to foreground app stream.");
  }


  @override
  void dispose() {
    // Cancel the stream subscription when the widget is disposed
    _foregroundAppSubscription?.cancel();
    // Optional: Call plugin's dispose if it exists and is needed
    // ForegroundAppMonitor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Foreground App Monitor'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Current Foreground App:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _foregroundApp,
                style: TextStyle(fontSize: 20, color: _error != null ? Colors.red : Colors.blue),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                    textAlign: TextAlign.center,
                  ),
                ),
                // TODO: Optionally add a button here to request permission
                // ElevatedButton(
                //   onPressed: () { /* Open Usage Access Settings */ },
                //   child: Text('Grant Permission'),
                // )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
