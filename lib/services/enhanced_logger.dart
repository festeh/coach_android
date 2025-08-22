import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import '../models/log_entry.dart';

final _log = Logger('EnhancedLogger');

class EnhancedLogger {
  static const int _maxLogs = 500;
  static const String _logsKey = 'enhanced_logs';
  static final StreamController<LogEntry> _logStreamController = 
      StreamController<LogEntry>.broadcast();
  
  static Stream<LogEntry> get logStream => _logStreamController.stream;
  static final List<LogEntry> _inMemoryLogs = [];
  
  static LogEntry log({
    required LogLevel level,
    required LogSource source,
    required LogCategory category,
    required String message,
    Map<String, dynamic>? metadata,
    String? stackTrace,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      source: source,
      category: category,
      message: message,
      metadata: metadata,
      stackTrace: stackTrace,
    );
    
    _addLog(entry);
    return entry;
  }
  
  static void debug(LogSource source, LogCategory category, String message, 
      [Map<String, dynamic>? metadata]) {
    log(
      level: LogLevel.debug,
      source: source,
      category: category,
      message: message,
      metadata: metadata,
    );
  }
  
  static void info(LogSource source, LogCategory category, String message, 
      [Map<String, dynamic>? metadata]) {
    log(
      level: LogLevel.info,
      source: source,
      category: category,
      message: message,
      metadata: metadata,
    );
  }
  
  static void warning(LogSource source, LogCategory category, String message, 
      [Map<String, dynamic>? metadata]) {
    log(
      level: LogLevel.warning,
      source: source,
      category: category,
      message: message,
      metadata: metadata,
    );
  }
  
  static void error(LogSource source, LogCategory category, String message, 
      [Map<String, dynamic>? metadata, String? stackTrace]) {
    log(
      level: LogLevel.error,
      source: source,
      category: category,
      message: message,
      metadata: metadata,
      stackTrace: stackTrace,
    );
  }
  
  static void critical(LogSource source, LogCategory category, String message, 
      [Map<String, dynamic>? metadata, String? stackTrace]) {
    log(
      level: LogLevel.critical,
      source: source,
      category: category,
      message: message,
      metadata: metadata,
      stackTrace: stackTrace,
    );
  }
  
  static void _addLog(LogEntry entry) {
    // Add to in-memory cache
    _inMemoryLogs.add(entry);
    if (_inMemoryLogs.length > _maxLogs) {
      _inMemoryLogs.removeAt(0);
    }
    
    // Emit to stream for real-time updates
    _logStreamController.add(entry);
    
    // Persist asynchronously
    _persistLog(entry);
    
    // Also log to standard logger for debugging
    final logLevel = _mapToLoggingLevel(entry.level);
    Logger(entry.source.displayName).log(
      logLevel,
      '${entry.category.displayName}: ${entry.message}',
    );
  }
  
  static Level _mapToLoggingLevel(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return Level.FINE;
      case LogLevel.info:
        return Level.INFO;
      case LogLevel.warning:
        return Level.WARNING;
      case LogLevel.error:
        return Level.SEVERE;
      case LogLevel.critical:
        return Level.SHOUT;
    }
  }
  
  static Future<void> _persistLog(LogEntry entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingLogs = await getLogs();
      
      existingLogs.add(entry);
      
      // Keep only the most recent logs
      while (existingLogs.length > _maxLogs) {
        existingLogs.removeAt(0);
      }
      
      final jsonLogs = existingLogs.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_logsKey, jsonLogs);
    } catch (e) {
      _log.severe('Failed to persist log: $e');
    }
  }
  
  static Future<List<LogEntry>> getLogs({
    LogLevel? minLevel,
    LogSource? source,
    LogCategory? category,
    DateTime? since,
    int? limit,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonLogs = prefs.getStringList(_logsKey) ?? [];
      
      var logs = jsonLogs
          .map((json) => LogEntry.fromJson(jsonDecode(json)))
          .toList();
      
      // Apply filters
      if (minLevel != null) {
        logs = logs.where((log) => log.level.priority >= minLevel.priority).toList();
      }
      
      if (source != null) {
        logs = logs.where((log) => log.source == source).toList();
      }
      
      if (category != null) {
        logs = logs.where((log) => log.category == category).toList();
      }
      
      if (since != null) {
        logs = logs.where((log) => log.timestamp.isAfter(since)).toList();
      }
      
      // Sort by timestamp (newest first)
      logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (limit != null && logs.length > limit) {
        logs = logs.take(limit).toList();
      }
      
      return logs;
    } catch (e) {
      _log.severe('Failed to retrieve logs: $e');
      return [];
    }
  }
  
  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logsKey);
      _inMemoryLogs.clear();
      
      info(LogSource.system, LogCategory.system, 'Logs cleared');
    } catch (e) {
      _log.severe('Failed to clear logs: $e');
    }
  }
  
  static Future<String> exportLogs({
    LogLevel? minLevel,
    LogSource? source,
    LogCategory? category,
    DateTime? since,
  }) async {
    final logs = await getLogs(
      minLevel: minLevel,
      source: source,
      category: category,
      since: since,
    );
    
    final buffer = StringBuffer();
    buffer.writeln('Coach App Logs Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('=' * 80);
    buffer.writeln();
    
    for (final log in logs) {
      buffer.writeln('[${log.timestamp.toIso8601String()}] '
          '[${log.level.displayName}] '
          '[${log.source.displayName}] '
          '[${log.category.displayName}]');
      buffer.writeln(log.message);
      
      if (log.metadata != null && log.metadata!.isNotEmpty) {
        buffer.writeln('Metadata: ${jsonEncode(log.metadata)}');
      }
      
      if (log.stackTrace != null) {
        buffer.writeln('Stack trace:');
        buffer.writeln(log.stackTrace);
      }
      
      buffer.writeln('-' * 40);
    }
    
    return buffer.toString();
  }
  
  static List<LogEntry> getInMemoryLogs() {
    return List.unmodifiable(_inMemoryLogs);
  }
  
  static void dispose() {
    _logStreamController.close();
  }
}

// Provider for accessing logger in widgets
final enhancedLoggerProvider = Provider<EnhancedLogger>((ref) {
  ref.onDispose(() => EnhancedLogger.dispose());
  return EnhancedLogger();
});

// Provider for log stream
final logStreamProvider = StreamProvider<LogEntry>((ref) {
  return EnhancedLogger.logStream;
});

// Provider for filtered logs
final filteredLogsProvider = FutureProvider.family<List<LogEntry>, LogFilter>((ref, filter) async {
  return await EnhancedLogger.getLogs(
    minLevel: filter.minLevel,
    source: filter.source,
    category: filter.category,
    since: filter.since,
    limit: filter.limit,
  );
});

class LogFilter {
  final LogLevel? minLevel;
  final LogSource? source;
  final LogCategory? category;
  final DateTime? since;
  final int? limit;
  
  const LogFilter({
    this.minLevel,
    this.source,
    this.category,
    this.since,
    this.limit,
  });
}