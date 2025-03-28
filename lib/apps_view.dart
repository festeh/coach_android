import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/app_info.dart';
import 'state.dart'; // Import the new state file

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
    final selectedApps = await AppState.loadSelectedApps();
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
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Total Apps: ${_installedApps.length}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _installedApps.length,
                      itemBuilder: (context, index) {
                        final app = _installedApps[index];
                        return ListTile(
                          title: Text(app.name),
                          leading: IconButton(
                            icon: Icon(
                              _selectedApps.contains(app.name)
                                  ? Icons.check_box
                                  : Icons.check_box_outline_blank,
                            ),
                            onPressed: () {
                              setState(() {
                                if (_selectedApps.contains(app.name)) {
                                  _selectedApps.remove(app.name);
                                } else {
                                  _selectedApps.add(app.name);
                                }
                                AppState.saveSelectedApps(_selectedApps);
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
