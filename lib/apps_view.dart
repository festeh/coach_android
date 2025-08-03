import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async'; // Import async
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

  String _getFocusingStateText(FocusingState focusingState) {
    if (focusingState == FocusingState.focusing) {
      return 'Focusing';
    } else if (focusingState == FocusingState.notFocusing) {
      return 'Not Focusing';
    } else if (focusingState == FocusingState.errorNoSuchKey) {
      return 'Error: No such key';
    } else if (focusingState == FocusingState.loading) {
      return 'Loading...';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final text = _getFocusingStateText(focusingState);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Focusing Status:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: focusingState == FocusingState.focusing
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.tertiary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: focusingState == FocusingState.focusing
                            ? Theme.of(context).colorScheme.onSecondary
                            : Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    shape: const CircleBorder(),
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        AppState.forceFetchFocusingState();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.refresh,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Total Apps: ${installedApps.length}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: installedApps.length,
            itemBuilder: (context, index) {
              final app = installedApps[index];
              final isSelected = selectedAppPackages.contains(app.packageName);
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    app.name,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  leading: IconButton(
                    icon: Icon(
                      isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      onAppSelected(app.packageName, !isSelected);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
