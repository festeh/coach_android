import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Import async
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart'; // Import background service
import 'models/app_info.dart';
import 'state.dart';
import 'package:logging/logging.dart';

final _log = Logger('AppsView');

class AppsView extends StatefulWidget {
  const AppsView({super.key});

  @override
  State<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends State<AppsView> {
  static const platform = MethodChannel('com.example.coach_android/appCount');
  List<AppInfo> _installedApps = [];
  // Store selected package names
  Set<String> _selectedAppPackages = {};
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>?>? _focusingStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listenForFocusingUpdates();
  }

  @override
  void dispose() {
    // Cancel the subscription when the widget is disposed
    _focusingStateSubscription?.cancel();
    super.dispose();
  }

  void _listenForFocusingUpdates() {
    _focusingStateSubscription = FlutterBackgroundService()
        .on('updateFocusingState')
        .listen((event) {
          if (event != null && event.containsKey('isFocusing')) {
            final isFocusing = event['isFocusing'] as bool;
            _log.info('Received focusing update from background: $isFocusing');
            // Update the AppState notifier, which triggers the ValueListenableBuilder
            AppState.updateFocusingState(isFocusing);
          }
        });
  }

  Future<void> _loadInitialData() async {
    // Load both selected apps and the focusing state
    final selectedAppPackages = await AppState.loadSelectedAppPackages();
    await AppState.loadFocusingState(); // Load focusing state here

    // Check if the widget is still mounted before calling setState
    if (!mounted) return;

    setState(() {
      _selectedAppPackages = selectedAppPackages;
    });
    await _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
        'getInstalledApps',
      );
      setState(() {
        _installedApps =
            result
                .cast<Map<dynamic, dynamic>>()
                .map((map) => AppInfo.fromMap(map))
                .toList();
        _isLoading = false;
      });
    } on PlatformException catch (e) {
      setState(() {
        _installedApps = [];
        _isLoading = false;
      });
      debugPrint("Failed to get installed apps: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apps'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ValueListenableBuilder<FocusingState>(
                valueListenable: AppState.focusingNotifier,
                builder: (context, focusingState, child) {
                  _log.info('Focusing state: $focusingState');
                  return _AppsListContent(
                    focusingState: focusingState,
                    installedApps: _installedApps,
                    // Pass selected package names
                    selectedAppPackages: _selectedAppPackages,
                    onAppSelected: (packageName, isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selectedAppPackages.add(packageName);
                        } else {
                          _selectedAppPackages.remove(packageName);
                        }
                        // Save the updated set of package names
                        AppState.saveSelectedApps(_selectedAppPackages);
                      });
                    },
                  );
                },
              ),
    );
  }
}

class _AppsListContent extends StatelessWidget {
  final FocusingState focusingState;
  final List<AppInfo> installedApps;
  // Expect selected package names
  final Set<String> selectedAppPackages;
  // Callback provides package name
  final Function(String packageName, bool isSelected) onAppSelected;

  const _AppsListContent({
    required this.focusingState,
    required this.installedApps,
    required this.selectedAppPackages,
    required this.onAppSelected,
  });

  @override
  Widget build(BuildContext context) {
    String text = '';
    if (focusingState == FocusingState.focusing) {
      text = 'Focusing';
    } else if (focusingState == FocusingState.notFocusing) {
      text = 'Not Focusing';
    } else if (focusingState == FocusingState.errorNoSuchKey) {
      text = 'Error: No such key';
    } else if (focusingState == FocusingState.loading) {
      text = 'Loading...';
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Focusing Status:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                text,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: const Divider(),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Total Apps: ${installedApps.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: installedApps.length,
            itemBuilder: (context, index) {
              final app = installedApps[index];
              return ListTile(
                title: Text(app.name),
                leading: IconButton(
                  icon: Icon(
                    // Check using package name
                    selectedAppPackages.contains(app.packageName)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  onPressed: () {
                    // Check using package name
                    final currentlySelected = selectedAppPackages.contains(
                      app.packageName,
                    );
                    // Pass package name to callback
                    onAppSelected(app.packageName, !currentlySelected);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
