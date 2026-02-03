import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../models/app_info.dart';
import '../models/app_rule.dart';
import '../services/focus_service.dart';
import '../services/usage_database.dart';
import '../state_management/providers/app_rules_provider.dart';
import 'rule_editor_dialog.dart';

class AppDetailBottomSheet extends ConsumerStatefulWidget {
  final AppInfo app;
  final bool isCoachEnabled;
  final ValueChanged<bool> onToggle;

  const AppDetailBottomSheet({
    super.key,
    required this.app,
    required this.isCoachEnabled,
    required this.onToggle,
  });

  @override
  ConsumerState<AppDetailBottomSheet> createState() =>
      _AppDetailBottomSheetState();
}

class _AppDetailBottomSheetState extends ConsumerState<AppDetailBottomSheet> {
  bool _isLoading = true;
  String _usageTime = '';
  int _blockedCount = 0;
  late bool _coachEnabled;
  Map<String, RuleCounters> _ruleCounters = {};
  Set<String> _pendingChallengeIds = {};

  @override
  void initState() {
    super.initState();
    _coachEnabled = widget.isCoachEnabled;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final today = DateTime.now();

    final results = await Future.wait([
      FocusService.getAppUsageStats(today),
      UsageDatabase.instance.getBlockedAppsForDay(today),
    ]);

    final usageList = results[0] as List<AppUsageEntry>;
    final blockedList = results[1] as List<BlockedAppEntry>;

    final usage = usageList
        .where((e) => e.packageName == widget.app.packageName)
        .toList();
    final blocked = blockedList
        .where((e) => e.packageName == widget.app.packageName)
        .toList();

    // Load rule counters and pending challenges
    final rules = ref.read(rulesForAppProvider(widget.app.packageName));
    final counters = <String, RuleCounters>{};
    for (final rule in rules) {
      counters[rule.id] = await UsageDatabase.instance.getCounters(rule.id);
    }

    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(StorageKeys.pendingChallenges);
    final pendingIds = pendingJson != null
        ? (jsonDecode(pendingJson) as List).cast<String>().toSet()
        : <String>{};

    if (mounted) {
      setState(() {
        _usageTime = usage.isNotEmpty ? usage.first.formattedTime : '0m';
        _blockedCount = blocked.isNotEmpty ? blocked.first.count : 0;
        _ruleCounters = counters;
        _pendingChallengeIds = pendingIds;
        _isLoading = false;
      });
    }
  }

  Future<void> _addRule() async {
    final result = await showDialog<RuleEditorResult>(
      context: context,
      builder: (ctx) => const RuleEditorDialog(),
    );
    if (result == null) return;

    await ref.read(appRulesProvider.notifier).addRule(
          packageName: widget.app.packageName,
          everyN: result.everyN,
          maxTriggers: result.maxTriggers,
          challengeType: result.challengeType,
        );

    // Reload counters for the new rule
    _loadRuleCounters();
  }

  Future<void> _editRule(AppRule rule) async {
    final result = await showDialog<RuleEditorResult>(
      context: context,
      builder: (ctx) => RuleEditorDialog(existingRule: rule),
    );
    if (result == null) return;

    await ref.read(appRulesProvider.notifier).updateRule(
          rule.copyWith(
            everyN: result.everyN,
            maxTriggers: result.maxTriggers,
            challengeType: result.challengeType,
          ),
        );
  }

  Future<void> _resetRule(String ruleId) async {
    await ref.read(appRulesProvider.notifier).resetRule(ruleId);
    await _loadRuleCounters();
    // Reload pending challenges
    final prefs = await SharedPreferences.getInstance();
    final pendingJson = prefs.getString(StorageKeys.pendingChallenges);
    if (mounted) {
      setState(() {
        _pendingChallengeIds = pendingJson != null
            ? (jsonDecode(pendingJson) as List).cast<String>().toSet()
            : <String>{};
      });
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    await ref.read(appRulesProvider.notifier).deleteRule(ruleId);
    setState(() {
      _ruleCounters.remove(ruleId);
    });
  }

  Future<void> _loadRuleCounters() async {
    final rules = ref.read(rulesForAppProvider(widget.app.packageName));
    final counters = <String, RuleCounters>{};
    for (final rule in rules) {
      counters[rule.id] = await UsageDatabase.instance.getCounters(rule.id);
    }
    if (mounted) {
      setState(() {
        _ruleCounters = counters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rules = ref.watch(rulesForAppProvider(widget.app.packageName));

    return SafeArea(
      top: false,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.app.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 24),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            _buildStatRow(
              context,
              Icons.access_time,
              "Today's usage",
              _usageTime,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              Icons.app_blocking,
              'Opened during focus',
              '${_blockedCount}x',
              highlight: _blockedCount > 0,
            ),
          ],
          const Divider(height: 24),
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _coachEnabled,
                  onChanged: (value) {
                    setState(() {
                      _coachEnabled = value ?? false;
                    });
                    widget.onToggle(_coachEnabled);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              Text('Coach Enabled', style: theme.textTheme.bodyLarge),
            ],
          ),
          const Divider(height: 24),
          Text('Rules', style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
          )),
          const SizedBox(height: 8),
          ...rules.map((rule) => _buildRuleTile(context, rule)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _addRule,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Rule'),
            ),
          ),
        ],
      ),
      ),
    ),
    );
  }

  Widget _buildRuleTile(BuildContext context, AppRule rule) {
    final theme = Theme.of(context);
    final counters = _ruleCounters[rule.id];
    final openCount = counters?.openCount ?? 0;
    final triggerCount = counters?.triggerCount ?? 0;
    final isPending = _pendingChallengeIds.contains(rule.id);
    final maxReached = triggerCount >= rule.maxTriggers;
    final opensUntilNext = rule.everyN - (openCount % rule.everyN);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _editRule(rule),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Every ${_ordinal(rule.everyN)} open',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => _resetRule(rule.id),
                    child: Tooltip(
                      message: 'Reset counters',
                      child: Icon(
                        Icons.restart_alt,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _deleteRule(rule.id),
                    child: Icon(
                      Icons.close,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (rule.challengeType != 'none')
                _buildRuleStatLine(theme, 'Challenge', _challengeName(rule.challengeType)),
              _buildRuleStatLine(theme, 'Opens today', '$openCount'),
              _buildRuleStatLine(
                theme,
                'Triggered',
                '$triggerCount / ${rule.maxTriggers}',
                highlight: maxReached,
              ),
              if (maxReached)
                _buildRuleStatLine(theme, 'Next trigger', 'Max reached',
                    highlight: true)
              else
                _buildRuleStatLine(
                    theme, 'Next trigger', 'in $opensUntilNext open${opensUntilNext == 1 ? '' : 's'}'),
              if (isPending)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.hourglass_top,
                          size: 14, color: theme.colorScheme.tertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Pending challenge',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleStatLine(ThemeData theme, String label, String value,
      {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
                color: highlight ? theme.colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _challengeName(String type) {
    switch (type) {
      case 'longPress':
        return 'Long Press';
      case 'typing':
        return 'Typing';
      default:
        return 'None';
    }
  }

  String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    switch (n % 10) {
      case 1:
        return '${n}st';
      case 2:
        return '${n}nd';
      case 3:
        return '${n}rd';
      default:
        return '${n}th';
    }
  }

  Widget _buildStatRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight
              ? theme.colorScheme.error
              : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyLarge),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? theme.colorScheme.error : null,
          ),
        ),
      ],
    );
  }
}
