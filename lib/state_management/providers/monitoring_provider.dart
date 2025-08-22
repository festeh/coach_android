import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../models/monitoring_state.dart';

final _log = Logger('MonitoringProvider');

class MonitoringNotifier extends StateNotifier<MonitoringState> {
  MonitoringNotifier() : super(const MonitoringState());

  void updateMonitoringStatus(bool isMonitoring) {
    _log.info('Updating monitoring status: $isMonitoring');
    state = state.copyWith(
      isMonitoring: isMonitoring,
      lastChecked: DateTime.now(),
    );
  }

  void updatePermissions({
    bool? hasUsageStats,
    bool? hasOverlay,
  }) {
    _log.info('Updating permissions: usageStats=$hasUsageStats, overlay=$hasOverlay');
    state = state.copyWith(
      hasUsageStatsPermission: hasUsageStats ?? state.hasUsageStatsPermission,
      hasOverlayPermission: hasOverlay ?? state.hasOverlayPermission,
    );
  }

  void updateForegroundApp(String? packageName) {
    if (packageName != state.currentForegroundApp) {
      _log.fine('Foreground app changed: $packageName');
      state = state.copyWith(
        currentForegroundApp: packageName,
        lastChecked: DateTime.now(),
      );
    }
  }

  void startMonitoring() {
    updateMonitoringStatus(true);
  }

  void stopMonitoring() {
    updateMonitoringStatus(false);
  }
}

final monitoringProvider = StateNotifierProvider<MonitoringNotifier, MonitoringState>((ref) {
  return MonitoringNotifier();
});