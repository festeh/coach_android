import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:logging/logging.dart';

final _log = Logger('FocusOverlay');

// --- Overlay Widget UI ---
class FocusOverlayWidget extends StatelessWidget {
  const FocusOverlayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MaterialApp as the root for Material Design widgets like ElevatedButton
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Colors.transparent,
      home: Scaffold(
        // Make Scaffold background transparent
        backgroundColor: Colors.transparent,
        body: Center(
          child: Card(
            // Add some elevation and rounded corners
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Fit content size
                children: [
                  const Text(
                    "Time to focus",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Attempt to close the overlay
                        await FlutterOverlayWindow.closeOverlay();
                        _log.info('Overlay closed via button.');
                      } catch (e) {
                        _log.severe('Error closing overlay: $e');
                      }
                    },
                    child: const Text("Close"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
