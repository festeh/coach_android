import 'package:flutter/material.dart';
import '../models/app_info.dart';
import '../services/focus_service.dart';
import '../services/usage_database.dart';

class AppDetailBottomSheet extends StatefulWidget {
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
  State<AppDetailBottomSheet> createState() => _AppDetailBottomSheetState();
}

class _AppDetailBottomSheetState extends State<AppDetailBottomSheet> {
  bool _isLoading = true;
  String _usageTime = '';
  int _blockedCount = 0;
  late bool _coachEnabled;

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

    if (mounted) {
      setState(() {
        _usageTime = usage.isNotEmpty ? usage.first.formattedTime : '0m';
        _blockedCount = blocked.isNotEmpty ? blocked.first.count : 0;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
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
        ],
      ),
    );
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
