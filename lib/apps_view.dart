import 'package:coach_android/persistent_log.dart';
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
  // Store selected package names
  Set<String> _selectedAppPackages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      AppState.loadSelectedAppPackages(), // Load package names
      AppState.loadFocusingState(), // Load focusing state here
    ]);
    final selectedAppPackages = results[0] as Set<String>;

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
              : ValueListenableBuilder<bool>(
                valueListenable: AppState.focusingNotifier,
                builder: (context, isFocusing, child) {
                  _log.info('isFocusing: $isFocusing');
                  return _AppsListContent(
                    isFocusing: isFocusing,
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
  final bool isFocusing;
  final List<AppInfo> installedApps;
  // Expect selected package names
  final Set<String> selectedAppPackages;
  // Callback provides package name
  final Function(String packageName, bool isSelected) onAppSelected;

  const _AppsListContent({
    required this.isFocusing,
    required this.installedApps,
    required this.selectedAppPackages,
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
                    // Check using package name
                    selectedAppPackages.contains(app.packageName)
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  onPressed: () {
                    // Check using package name
                    final currentlySelected =
                        selectedAppPackages.contains(app.packageName);
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
