import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';

final _log = Logger('UsageDatabase');

class UsageDatabase {
  static final UsageDatabase instance = UsageDatabase._internal();
  static Database? _database;

  UsageDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'usage_events.db');

    _log.info('Initializing database at: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        _log.info('Creating database tables...');
        await db.execute('''
          CREATE TABLE events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp INTEGER NOT NULL,
            event_type TEXT NOT NULL,
            package_name TEXT,
            during_focus INTEGER DEFAULT 0,
            duration INTEGER,
            metadata TEXT
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_events_timestamp ON events(timestamp)');
        await db.execute(
            'CREATE INDEX idx_events_type ON events(event_type)');
        await db.execute('''
          CREATE TABLE rule_counters (
            rule_id TEXT NOT NULL,
            date TEXT NOT NULL,
            open_count INTEGER DEFAULT 0,
            trigger_count INTEGER DEFAULT 0,
            PRIMARY KEY (rule_id, date)
          )
        ''');
        _log.info('Database tables created');
      },
    );
  }

  Future<void> init() async {
    await database;
    _log.info('UsageDatabase initialized');
  }

  Future<void> logAppOpened(String packageName, bool duringFocus) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.insert('events', {
      'timestamp': timestamp,
      'event_type': 'app_opened',
      'package_name': packageName,
      'during_focus': duringFocus ? 1 : 0,
    });

    _log.fine('Logged app_opened: $packageName, duringFocus: $duringFocus');
  }

  Future<void> logFocusStarted() async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.insert('events', {
      'timestamp': timestamp,
      'event_type': 'focus_started',
    });

    _log.info('Logged focus_started');
  }

  Future<void> logFocusEnded(int duration) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await db.insert('events', {
      'timestamp': timestamp,
      'event_type': 'focus_ended',
      'duration': duration,
    });

    _log.info('Logged focus_ended, duration: $duration seconds');
  }

  Future<DailyStats> getDailyStats(DateTime date) async {
    final db = await database;

    // Get start and end of day in seconds
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTimestamp = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endOfDay.millisecondsSinceEpoch ~/ 1000;

    // Count focus sessions (focus_started events)
    final focusCountResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM events
      WHERE event_type = 'focus_started'
      AND timestamp >= ? AND timestamp < ?
    ''', [startTimestamp, endTimestamp]);
    final focusCount = Sqflite.firstIntValue(focusCountResult) ?? 0;

    // Sum focus durations (from focus_ended events)
    final totalFocusTimeResult = await db.rawQuery('''
      SELECT COALESCE(SUM(duration), 0) as total FROM events
      WHERE event_type = 'focus_ended'
      AND timestamp >= ? AND timestamp < ?
    ''', [startTimestamp, endTimestamp]);
    final totalFocusTime = Sqflite.firstIntValue(totalFocusTimeResult) ?? 0;

    // Count blocked app opens (app_opened during focus)
    final blockedAppOpensResult = await db.rawQuery('''
      SELECT COUNT(*) as count FROM events
      WHERE event_type = 'app_opened' AND during_focus = 1
      AND timestamp >= ? AND timestamp < ?
    ''', [startTimestamp, endTimestamp]);
    final blockedAppOpens = Sqflite.firstIntValue(blockedAppOpensResult) ?? 0;

    return DailyStats(
      date: date,
      focusCount: focusCount,
      totalFocusTimeSeconds: totalFocusTime,
      blockedAppOpens: blockedAppOpens,
    );
  }

  Future<List<BlockedAppEntry>> getBlockedAppsForDay(
    DateTime date, {
    Set<String>? monitoredPackages,
  }) async {
    final db = await database;

    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startTimestamp = startOfDay.millisecondsSinceEpoch ~/ 1000;
    final endTimestamp = endOfDay.millisecondsSinceEpoch ~/ 1000;

    String query = '''
      SELECT package_name, COUNT(*) as count
      FROM events
      WHERE event_type = 'app_opened' AND during_focus = 1
      AND timestamp >= ? AND timestamp < ?
    ''';
    List<dynamic> args = [startTimestamp, endTimestamp];

    // Filter by monitored packages if provided
    if (monitoredPackages != null && monitoredPackages.isNotEmpty) {
      final placeholders = monitoredPackages.map((_) => '?').join(', ');
      query += ' AND package_name IN ($placeholders)';
      args.addAll(monitoredPackages);
    }

    query += '''
      GROUP BY package_name
      ORDER BY count DESC
    ''';

    final results = await db.rawQuery(query, args);

    return results.map((row) => BlockedAppEntry(
      packageName: row['package_name'] as String,
      count: row['count'] as int,
    )).toList();
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<int> incrementOpenCount(String ruleId) async {
    final db = await database;
    final date = _todayString();

    await db.rawInsert('''
      INSERT INTO rule_counters (rule_id, date, open_count, trigger_count)
      VALUES (?, ?, 1, 0)
      ON CONFLICT(rule_id, date) DO UPDATE SET open_count = open_count + 1
    ''', [ruleId, date]);

    final result = await db.rawQuery(
      'SELECT open_count FROM rule_counters WHERE rule_id = ? AND date = ?',
      [ruleId, date],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> incrementTriggerCount(String ruleId) async {
    final db = await database;
    final date = _todayString();

    await db.rawUpdate(
      'UPDATE rule_counters SET trigger_count = trigger_count + 1 WHERE rule_id = ? AND date = ?',
      [ruleId, date],
    );

    final result = await db.rawQuery(
      'SELECT trigger_count FROM rule_counters WHERE rule_id = ? AND date = ?',
      [ruleId, date],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<RuleCounters> getCounters(String ruleId) async {
    final db = await database;
    final date = _todayString();

    final result = await db.rawQuery(
      'SELECT open_count, trigger_count FROM rule_counters WHERE rule_id = ? AND date = ?',
      [ruleId, date],
    );

    if (result.isEmpty) {
      return RuleCounters(openCount: 0, triggerCount: 0);
    }

    return RuleCounters(
      openCount: result.first['open_count'] as int,
      triggerCount: result.first['trigger_count'] as int,
    );
  }

  Future<void> cleanupOldCounters() async {
    final db = await database;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final cutoff = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final deleted = await db.rawDelete(
      'DELETE FROM rule_counters WHERE date < ?',
      [cutoff],
    );
    if (deleted > 0) {
      _log.info('Cleaned up $deleted old rule counter rows');
    }
  }
}

class RuleCounters {
  final int openCount;
  final int triggerCount;

  RuleCounters({required this.openCount, required this.triggerCount});
}

class DailyStats {
  final DateTime date;
  final int focusCount;
  final int totalFocusTimeSeconds;
  final int blockedAppOpens;

  DailyStats({
    required this.date,
    required this.focusCount,
    required this.totalFocusTimeSeconds,
    required this.blockedAppOpens,
  });

  String get formattedFocusTime {
    final hours = totalFocusTimeSeconds ~/ 3600;
    final minutes = (totalFocusTimeSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class BlockedAppEntry {
  final String packageName;
  final int count;

  BlockedAppEntry({
    required this.packageName,
    required this.count,
  });
}
