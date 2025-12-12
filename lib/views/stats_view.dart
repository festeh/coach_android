import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/usage_database.dart';
import '../services/focus_service.dart';
import '../constants/storage_keys.dart';

class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  DateTime _selectedDate = DateTime.now();
  DailyStats? _stats;
  List<BlockedAppEntry>? _blockedApps;
  List<AppUsageEntry>? _appUsage;
  Set<String> _monitoredPackages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load monitored packages from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final monitoredAppsJson = prefs.getString(StorageKeys.selectedAppPackages);
      if (monitoredAppsJson != null) {
        final List<dynamic> packagesList = jsonDecode(monitoredAppsJson);
        _monitoredPackages = packagesList.cast<String>().toSet();
      }

      // Load stats
      final stats = await UsageDatabase.instance.getDailyStats(_selectedDate);
      final blockedApps = await UsageDatabase.instance.getBlockedAppsForDay(
        _selectedDate,
        monitoredPackages: _monitoredPackages,
      );
      final appUsage = await FocusService.getAppUsageStats(_selectedDate);

      setState(() {
        _stats = stats;
        _blockedApps = blockedApps;
        _appUsage = appUsage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _goToPreviousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
    _loadStats();
  }

  void _goToNextDay() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final nextDay = _selectedDate.add(const Duration(days: 1));

    // Don't go past today
    if (nextDay.isBefore(tomorrow)) {
      setState(() {
        _selectedDate = nextDay;
      });
      _loadStats();
    }
  }

  bool _isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String _formatDate() {
    if (_isToday()) {
      return 'Today - ${DateFormat('MMM d').format(_selectedDate)}';
    }
    return DateFormat('EEE, MMM d').format(_selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date navigation
              _buildDateHeader(context),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Stats summary card
                _buildStatsCard(context),
                const SizedBox(height: 24),

                // App usage card
                if (_appUsage != null && _appUsage!.isNotEmpty)
                  _buildAppUsageCard(context),

                if (_appUsage != null && _appUsage!.isNotEmpty)
                  const SizedBox(height: 24),

                // Blocked apps during focus
                if (_blockedApps != null && _blockedApps!.isNotEmpty)
                  _buildBlockedAppsCard(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: _goToPreviousDay,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous day',
        ),
        Text(
          _formatDate(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          onPressed: _isToday() ? null : _goToNextDay,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next day',
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final stats = _stats;
    if (stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Daily Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow(
              context,
              Icons.timer,
              'Focus sessions',
              stats.focusCount.toString(),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              Icons.hourglass_bottom,
              'Total focus time',
              stats.formattedFocusTime,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              Icons.block,
              'Blocked app opens',
              stats.blockedAppOpens.toString(),
              highlight: stats.blockedAppOpens > 0,
            ),
          ],
        ),
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
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: highlight
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: highlight ? Theme.of(context).colorScheme.error : null,
          ),
        ),
      ],
    );
  }

  Widget _buildAppUsageCard(BuildContext context) {
    // Filter to show only apps with > 1 minute usage, limit to top 10
    final filteredUsage = _appUsage!
        .where((app) => app.totalTimeSeconds >= 60)
        .take(10)
        .toList();

    if (filteredUsage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  'App Usage',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...filteredUsage.map((app) => _buildAppUsageRow(context, app)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppUsageRow(BuildContext context, AppUsageEntry app) {
    // Extract app name from package name (last part after the dot)
    final displayName = app.packageName.split('.').last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            app.formattedTime,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedAppsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.app_blocking, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Opened during focus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ..._blockedApps!.map((app) => _buildBlockedAppRow(context, app)),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedAppRow(BuildContext context, BlockedAppEntry app) {
    // Extract app name from package name (last part after the dot)
    final displayName = app.packageName.split('.').last;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Text(
            '${app.count}x',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
