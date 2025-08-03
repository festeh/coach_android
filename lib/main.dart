import 'package:flutter/material.dart';
import 'app.dart';
import 'bg.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initBgService();
  runApp(const MyApp());
}
