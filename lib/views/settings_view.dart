import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/settings_service.dart';

class SettingsView extends StatefulWidget {
  final VoidCallback onThemeToggle;

  const SettingsView({super.key, required this.onThemeToggle});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  AppSettings _settings = const AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await SettingsService.loadSettings();
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(AppSettings settings) async {
    setState(() => _settings = settings);
    await SettingsService.saveSettings(settings);
  }

  Future<void> _resetDefaults() async {
    await _save(const AppSettings());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _SectionHeader('Appearance'),
                SwitchListTile(
                  title: const Text('Dark mode'),
                  value: isDark,
                  onChanged: (_) => widget.onThemeToggle(),
                ),
                const Divider(),
                _SectionHeader('Notifications'),
                _SliderTile(
                  title: 'Focus gap threshold',
                  subtitle:
                      'Time since last focus before showing a reminder',
                  value: _settings.focusGapThresholdMinutes,
                  min: 30,
                  max: 480,
                  divisions: 15,
                  formatLabel: _formatMinutes,
                  onChanged: (v) => _save(
                      _settings.copyWith(focusGapThresholdMinutes: v)),
                ),
                _SliderTile(
                  title: 'Reminder cooldown',
                  subtitle:
                      'Minimum time between reminder notifications',
                  value: _settings.reminderCooldownMinutes,
                  min: 15,
                  max: 255,
                  divisions: 16,
                  formatLabel: _formatMinutes,
                  onChanged: (v) => _save(
                      _settings.copyWith(reminderCooldownMinutes: v)),
                ),
                _SliderTile(
                  title: 'Activity timeout',
                  subtitle:
                      'Inactivity duration before considering user idle',
                  value: _settings.activityTimeoutMinutes,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  formatLabel: _formatMinutes,
                  onChanged: (v) => _save(
                      _settings.copyWith(activityTimeoutMinutes: v)),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: _resetDefaults,
                    child: const Text('Reset to defaults'),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatMinutes(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String Function(int) formatLabel;
  final ValueChanged<int> onChanged;

  const _SliderTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.formatLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              Text(formatLabel(value),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
            ],
          ),
          Text(subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  )),
          Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            label: formatLabel(value),
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
