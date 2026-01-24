import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/app_info.dart';
import '../services/installed_apps_service.dart';
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
  static final _log = Logger('AppsView');
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstalledApps();
    _checkPermissions();
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
      // Use shared service - it may already be initialized
      if (!InstalledAppsService.instance.isInitialized) {
        await InstalledAppsService.instance.init();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _log.warning("Failed to get installed apps: '$e'");
    }
  }

  List<AppInfo> get _installedApps => InstalledAppsService.instance.installedApps;

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
    // Sort apps: selected (blocked) first, then alphabetically
    final sortedApps = List<AppInfo>.from(_installedApps)
      ..sort((a, b) {
        final aSelected = appSelection.selectedPackages.contains(a.packageName);
        final bSelected = appSelection.selectedPackages.contains(b.packageName);
        if (aSelected && !bSelected) return -1;
        if (!aSelected && bSelected) return 1;
        return a.name.compareTo(b.name);
      });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: sortedApps.length,
      itemBuilder: (context, index) {
        final app = sortedApps[index];
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
