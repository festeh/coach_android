import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

final _log = Logger('PersistentLog');

class PersistentLog {
  static const _maxLogs = 20;
  static const _prefsKey = 'app_logs';

  PersistentLog._();

  static Future<void> addLog(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_prefsKey) ?? [];

      final timestamp = DateTime.now().toIso8601String();
      logs.add('[$timestamp] $message');

      if (logs.length > _maxLogs) {
        logs.removeRange(0, logs.length - _maxLogs);
      }

      await prefs.setStringList(_prefsKey, logs);
    } catch (e) {
      _log.warning('Error saving log to SharedPreferences: $e');
    }
  }

  static Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_prefsKey) ?? [];
    } catch (e) {
      _log.warning('Error retrieving logs from SharedPreferences: $e');
      return []; // Return empty list on error
    }
  }

  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      _log.warning('Error clearing logs from SharedPreferences: $e');
    }
  }
}
