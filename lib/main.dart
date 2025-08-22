import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'bg.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBgService();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
