import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/app_selection_state.dart';
import '../services/state_service.dart';
import 'focus_provider.dart';
import '../../app_monitor.dart';

final _log = Logger('AppSelectionProvider');

class AppSelectionNotifier extends StateNotifier<AppSelectionState> {
  final StateService _stateService;

  AppSelectionNotifier(this._stateService) : super(const AppSelectionState()) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    state = state.copyWith(isLoading: true);
    try {
      final selectedPackages = await _stateService.loadSelectedAppPackages();
      state = state.copyWith(
        selectedPackages: selectedPackages,
        isLoading: false,
      );
    } catch (e) {
      _log.severe('Error loading selected apps: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleApp(String packageName) async {
    final currentPackages = Set<String>.from(state.selectedPackages);
    
    if (currentPackages.contains(packageName)) {
      currentPackages.remove(packageName);
      _log.info('Removed app from selection: $packageName');
    } else {
      currentPackages.add(packageName);
      _log.info('Added app to selection: $packageName');
    }

    state = state.copyWith(selectedPackages: currentPackages);
    
    // Persist the changes
    await _stateService.saveSelectedApps(currentPackages);
    
    // Immediately sync to background isolate
    await updateMonitoredApps(currentPackages);
  }

  Future<void> setSelectedApps(Set<String> packages) async {
    state = state.copyWith(selectedPackages: packages);
    await _stateService.saveSelectedApps(packages);
    
    // Immediately sync to background isolate
    await updateMonitoredApps(packages);
  }

  Future<void> clearSelection() async {
    state = state.copyWith(selectedPackages: {});
    await _stateService.saveSelectedApps({});
    
    // Immediately sync to background isolate
    await updateMonitoredApps({});
  }
}

final appSelectionProvider = StateNotifierProvider<AppSelectionNotifier, AppSelectionState>((ref) {
  final stateService = ref.watch(stateServiceProvider);
  return AppSelectionNotifier(stateService);
});

// Helper provider to get just the selected packages
final selectedPackagesProvider = Provider<Set<String>>((ref) {
  return ref.watch(appSelectionProvider).selectedPackages;
});