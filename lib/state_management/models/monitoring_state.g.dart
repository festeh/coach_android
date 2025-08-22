// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'monitoring_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MonitoringStateImpl _$$MonitoringStateImplFromJson(
  Map<String, dynamic> json,
) => _$MonitoringStateImpl(
  isMonitoring: json['isMonitoring'] as bool? ?? false,
  hasUsageStatsPermission: json['hasUsageStatsPermission'] as bool? ?? false,
  hasOverlayPermission: json['hasOverlayPermission'] as bool? ?? false,
  currentForegroundApp: json['currentForegroundApp'] as String?,
  lastChecked: json['lastChecked'] == null
      ? null
      : DateTime.parse(json['lastChecked'] as String),
);

Map<String, dynamic> _$$MonitoringStateImplToJson(
  _$MonitoringStateImpl instance,
) => <String, dynamic>{
  'isMonitoring': instance.isMonitoring,
  'hasUsageStatsPermission': instance.hasUsageStatsPermission,
  'hasOverlayPermission': instance.hasOverlayPermission,
  'currentForegroundApp': instance.currentForegroundApp,
  'lastChecked': instance.lastChecked?.toIso8601String(),
};
