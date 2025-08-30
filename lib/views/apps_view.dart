import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/app_info.dart';
import '../state_management/providers/app_selection_provider.dart';
import '../state_management/providers/permissions_provider.dart';
import '../state_management/models/app_selection_state.dart';
import '../widgets/focus_status_widget.dart';


class AppsView extends ConsumerStatefulWidget {
  const AppsView({super.key});

  @override
  ConsumerState<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends ConsumerState<AppsView> {
  static const platform = MethodChannel('com.example.coach_android/appCount');
  List<AppInfo> _installedApps = [];
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>?>? _focusingStateSubscription;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _checkPermissions();
  }

  @override
  void dispose() {
    _focusingStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    // Small delay to ensure UI is fully loaded before showing dialog
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      await ref.read(permissionsProvider.notifier).checkAndRequestUsageStatsPermission(context);
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      if (mounted) {
        setState(() {
          _installedApps = result
              .cast<Map<dynamic, dynamic>>()
              .map((map) => AppInfo.fromMap(map))
              .toList();
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _installedApps = [];
          _isLoading = false;
        });
      }
      debugPrint("Failed to get installed apps: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final appSelection = ref.watch(appSelectionProvider);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(appSelection),
    );
  }

  Widget _buildContent(AppSelectionState appSelection) {
    return Column(
      children: [
        const FocusStatusWidget(),
        _buildAppCount(),
        Expanded(
          child: _buildAppList(appSelection),
        ),
      ],
    );
  }


  Widget _buildAppCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Total Apps: ${_installedApps.length}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAppList(AppSelectionState appSelection) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: _installedApps.length,
      itemBuilder: (context, index) {
        final app = _installedApps[index];
        final isSelected = appSelection.selectedPackages.contains(app.packageName);
        
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
                ref.read(appSelectionProvider.notifier).toggleApp(app.packageName);
              },
            ),
          ),
        );
      },
    );
  }
}
