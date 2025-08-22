import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

enum LogSource {
  service,
  webSocket,
  monitor,
  ui,
  system,
}

enum LogCategory {
  connection,
  monitoring,
  system,
  user,
  health,
  event,
}

@freezed
class LogEntry with _$LogEntry {
  const factory LogEntry({
    required DateTime timestamp,
    required LogLevel level,
    required LogSource source,
    required LogCategory category,
    required String message,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) = _LogEntry;

  factory LogEntry.fromJson(Map<String, dynamic> json) =>
      _$LogEntryFromJson(json);
}

extension LogLevelExtension on LogLevel {
  String get displayName {
    switch (this) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRIT';
    }
  }

  int get priority {
    switch (this) {
      case LogLevel.debug:
        return 0;
      case LogLevel.info:
        return 1;
      case LogLevel.warning:
        return 2;
      case LogLevel.error:
        return 3;
      case LogLevel.critical:
        return 4;
    }
  }
}

extension LogSourceExtension on LogSource {
  String get displayName {
    switch (this) {
      case LogSource.service:
        return 'Service';
      case LogSource.webSocket:
        return 'WebSocket';
      case LogSource.monitor:
        return 'Monitor';
      case LogSource.ui:
        return 'UI';
      case LogSource.system:
        return 'System';
    }
  }
}

extension LogCategoryExtension on LogCategory {
  String get displayName {
    switch (this) {
      case LogCategory.connection:
        return 'Connection';
      case LogCategory.monitoring:
        return 'Monitoring';
      case LogCategory.system:
        return 'System';
      case LogCategory.user:
        return 'User';
      case LogCategory.health:
        return 'Health';
      case LogCategory.event:
        return 'Event';
    }
  }
}