import 'package:flutter/material.dart';
import 'app.dart';
import 'bg.dart';
import 'overlay.dart';

@pragma("vm:entry-point")
void overlayEntryPoint() {
  runApp(const FocusOverlayWidget());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBgService();
  runApp(const MyApp());
}
