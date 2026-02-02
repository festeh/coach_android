import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../constants/storage_keys.dart';
import '../../models/app_rule.dart';
import '../../background_monitor_handler.dart';

final _log = Logger('AppRulesProvider');
const _uuid = Uuid();

class AppRulesNotifier extends Notifier<Map<String, AppRule>> {
  @override
  Map<String, AppRule> build() {
    _loadInitialState();
    return {};
  }

  Future<void> _loadInitialState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = prefs.getString(StorageKeys.appRules);
      if (rulesJson != null) {
        final Map<String, dynamic> rulesMap = jsonDecode(rulesJson);
        state = rulesMap.map((key, value) =>
            MapEntry(key, AppRule.fromJson(value as Map<String, dynamic>)));
      }
    } catch (e) {
      _log.severe('Error loading rules: $e');
    }
  }

  Future<void> addRule({
    required String packageName,
    required int everyN,
    required int maxTriggers,
    String challengeType = 'none',
  }) async {
    final id = _uuid.v4();
    final rule = AppRule(
      id: id,
      packageName: packageName,
      everyN: everyN,
      maxTriggers: maxTriggers,
      challengeType: challengeType,
    );

    final updated = Map<String, AppRule>.from(state);
    updated[id] = rule;
    state = updated;

    await _persist();
    _log.info('Added rule $id for $packageName: every ${everyN}th open, max $maxTriggers/day');
  }

  Future<void> updateRule(AppRule rule) async {
    final updated = Map<String, AppRule>.from(state);
    updated[rule.id] = rule;
    state = updated;

    await _persist();
    _log.info('Updated rule ${rule.id}');
  }

  Future<void> deleteRule(String ruleId) async {
    final updated = Map<String, AppRule>.from(state);
    updated.remove(ruleId);
    state = updated;

    await _persist();
    _log.info('Deleted rule $ruleId');
  }

  List<AppRule> getRulesForApp(String packageName) {
    return state.values
        .where((r) => r.packageName == packageName)
        .toList();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rulesJson = state.map((key, value) => MapEntry(key, value.toJson()));
      await prefs.setString(StorageKeys.appRules, jsonEncode(rulesJson));

      // Sync to background engine
      await BackgroundMonitorHandler.updateRules(state);
    } catch (e) {
      _log.severe('Error persisting rules: $e');
    }
  }
}

final appRulesProvider =
    NotifierProvider<AppRulesNotifier, Map<String, AppRule>>(
        AppRulesNotifier.new);

/// Helper provider to get rules for a specific app
final rulesForAppProvider =
    Provider.family<List<AppRule>, String>((ref, packageName) {
  final rules = ref.watch(appRulesProvider);
  return rules.values
      .where((r) => r.packageName == packageName)
      .toList();
});
