import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('com.example.coach_android/appCount');
  int _installedAppsCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getInstalledAppsCount();
  }

  Future<void> _getInstalledAppsCount() async {
    try {
      final int result = await platform.invokeMethod('getInstalledAppsCount');
      setState(() {
        _installedAppsCount = result;
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _installedAppsCount = -1;
        _isLoading = false;
      });
      debugPrint("Failed to get installed apps count: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Installed Apps Counter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Number of installed apps on your device:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _installedAppsCount >= 0
                        ? '$_installedAppsCount'
                        : 'Error retrieving count',
                    style: const TextStyle(
                        fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}
