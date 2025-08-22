import 'package:freezed_annotation/freezed_annotation.dart';

part 'monitoring_state.freezed.dart';
part 'monitoring_state.g.dart';

@freezed
class MonitoringState with _$MonitoringState {
  const factory MonitoringState({
    @Default(false) bool isMonitoring,
    @Default(false) bool hasUsageStatsPermission,
    @Default(false) bool hasOverlayPermission,
    String? currentForegroundApp,
    DateTime? lastChecked,
  }) = _MonitoringState;

  factory MonitoringState.fromJson(Map<String, dynamic> json) =>
      _$MonitoringStateFromJson(json);
}