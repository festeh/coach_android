import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/app_selection_state.dart';
import '../services/state_service.dart';
import '../../services/focus_service.dart';
import 'focus_provider.dart';
import '../../background_monitor_handler.dart';

final _log = Logger('AppSelectionProvider');

class AppSelectionNotifier extends AsyncNotifier<AppSelectionState> {
  @override
  Future<AppSelectionState> build() async {
    _log.info('Loading selected app packages...');
    final stateService = ref.read(stateServiceProvider);

    final selectedPackages = await stateService.loadSelectedAppPackages();
    _log.info('Loaded ${selectedPackages.length} selected app packages');

    return AppSelectionState(selectedPackages: selectedPackages);
  }

  StateService get _stateService => ref.read(stateServiceProvider);

  Future<void> toggleApp(String packageName) async {
    final current = state.value ?? const AppSelectionState();
    final currentPackages = Set<String>.from(current.selectedPackages);

    if (currentPackages.contains(packageName)) {
      currentPackages.remove(packageName);
      _log.info('Removed app from selection: $packageName');
    } else {
      currentPackages.add(packageName);
      _log.info('Added app to selection: $packageName');
    }

    state = AsyncData(current.copyWith(selectedPackages: currentPackages));

    // Persist the changes
    await _stateService.saveSelectedApps(currentPackages);
    _log.info('Persisted ${currentPackages.length} selected app packages');

    // Immediately sync to background isolate
    await BackgroundMonitorHandler.updateMonitoredPackages(currentPackages);
    // Notify the actual background engine via native service
    await FocusService.reloadMonitoredPackages();
    _log.info('Synced selection to background isolate');
  }

  Future<void> setSelectedApps(Set<String> packages) async {
    _log.info('Setting selected apps: ${packages.length} packages');
    state = AsyncData(AppSelectionState(selectedPackages: packages));
    await _stateService.saveSelectedApps(packages);

    // Immediately sync to background isolate
    await BackgroundMonitorHandler.updateMonitoredPackages(packages);
    await FocusService.reloadMonitoredPackages();
  }

  Future<void> clearSelection() async {
    _log.info('Clearing all selected apps');
    state = const AsyncData(AppSelectionState());
    await _stateService.saveSelectedApps({});

    // Immediately sync to background isolate
    await BackgroundMonitorHandler.updateMonitoredPackages({});
    await FocusService.reloadMonitoredPackages();
  }
}

final appSelectionProvider =
    AsyncNotifierProvider<AppSelectionNotifier, AppSelectionState>(
        AppSelectionNotifier.new);

/// Helper provider to get just the selected packages
final selectedPackagesProvider = Provider<Set<String>>((ref) {
  return ref.watch(appSelectionProvider).value?.selectedPackages ?? {};
});
