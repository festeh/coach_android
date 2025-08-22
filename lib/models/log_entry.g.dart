// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LogEntryImpl _$$LogEntryImplFromJson(Map<String, dynamic> json) =>
    _$LogEntryImpl(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: $enumDecode(_$LogLevelEnumMap, json['level']),
      source: $enumDecode(_$LogSourceEnumMap, json['source']),
      category: $enumDecode(_$LogCategoryEnumMap, json['category']),
      message: json['message'] as String,
      metadata: json['metadata'] as Map<String, dynamic>?,
      stackTrace: json['stackTrace'] as String?,
    );

Map<String, dynamic> _$$LogEntryImplToJson(_$LogEntryImpl instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'level': _$LogLevelEnumMap[instance.level]!,
      'source': _$LogSourceEnumMap[instance.source]!,
      'category': _$LogCategoryEnumMap[instance.category]!,
      'message': instance.message,
      'metadata': instance.metadata,
      'stackTrace': instance.stackTrace,
    };

const _$LogLevelEnumMap = {
  LogLevel.debug: 'debug',
  LogLevel.info: 'info',
  LogLevel.warning: 'warning',
  LogLevel.error: 'error',
  LogLevel.critical: 'critical',
};

const _$LogSourceEnumMap = {
  LogSource.service: 'service',
  LogSource.webSocket: 'webSocket',
  LogSource.monitor: 'monitor',
  LogSource.ui: 'ui',
  LogSource.system: 'system',
};

const _$LogCategoryEnumMap = {
  LogCategory.connection: 'connection',
  LogCategory.monitoring: 'monitoring',
  LogCategory.system: 'system',
  LogCategory.user: 'user',
  LogCategory.health: 'health',
  LogCategory.event: 'event',
};
