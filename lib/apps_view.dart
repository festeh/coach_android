import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Set<String> _selectedApps = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // Load both selected apps and focusing state concurrently
    final results = await Future.wait([
      AppState.loadSelectedApps(),
      AppState.loadFocusingState(), // Load focusing state here
    ]);
    final selectedApps = results[0] as Set<String>;
    // focusing state is loaded into the notifier by loadFocusingState

    setState(() {
      _selectedApps = selectedApps;
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
              : ValueListenableBuilder<bool>(
                valueListenable: AppState.focusingNotifier,
                builder: (context, isFocusing, child) {
                  _log.info('isFocusing: $isFocusing');
                  return _AppsListContent(
                    isFocusing: isFocusing,
                    installedApps: _installedApps,
                    selectedApps: _selectedApps,
                    onAppSelected: (appName, isSelected) {
                      setState(() {
                        if (isSelected) {
                          _selectedApps.add(appName);
                        } else {
                          _selectedApps.remove(appName);
                        }
                        AppState.saveSelectedApps(_selectedApps);
                      });
                    },
                  );
                },
              ),
    );
  }
}

class _AppsListContent extends StatelessWidget {
  final bool isFocusing;
  final List<AppInfo> installedApps;
  final Set<String> selectedApps;
  final Function(String appName, bool isSelected) onAppSelected;

  const _AppsListContent({
    required this.isFocusing,
    required this.installedApps,
    required this.selectedApps,
    required this.onAppSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                isFocusing ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isFocusing ? Colors.green : Colors.red,
                ),
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
                    selectedApps.contains(app.name)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  onPressed: () {
                    final currentlySelected = selectedApps.contains(app.name);
                    onAppSelected(app.name, !currentlySelected);
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
