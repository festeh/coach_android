import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/app_info.dart';
import '../models/app_settings.dart';
import '../services/focus_service.dart';
import '../services/installed_apps_service.dart';
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
  late final TextEditingController _overlayMessageController;
  late final TextEditingController _overlayButtonTextController;
  late final TextEditingController _rulesOverlayMessageController;
  late final TextEditingController _rulesOverlayButtonTextController;
  late final TextEditingController _typingPhraseController;

  @override
  void initState() {
    super.initState();
    _overlayMessageController = TextEditingController();
    _overlayButtonTextController = TextEditingController();
    _rulesOverlayMessageController = TextEditingController();
    _rulesOverlayButtonTextController = TextEditingController();
    _typingPhraseController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _overlayMessageController.dispose();
    _overlayButtonTextController.dispose();
    _rulesOverlayMessageController.dispose();
    _rulesOverlayButtonTextController.dispose();
    _typingPhraseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = await SettingsService.loadSettings();
    _overlayMessageController.text = settings.overlayMessage;
    _overlayButtonTextController.text = settings.overlayButtonText;
    _rulesOverlayMessageController.text = settings.rulesOverlayMessage;
    _rulesOverlayButtonTextController.text = settings.rulesOverlayButtonText;
    _typingPhraseController.text = settings.typingPhrase;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(AppSettings settings) async {
    setState(() => _settings = settings);
    await SettingsService.saveSettings(settings);
  }

  Future<void> _resetCoachOverlayDefaults() async {
    _overlayMessageController.text = '';
    _overlayButtonTextController.text = '';
    await _save(_settings.copyWith(
      overlayMessage: AppSettings.defaultOverlayMessage,
      overlayColor: AppSettings.defaultOverlayColor,
      overlayButtonText: AppSettings.defaultOverlayButtonText,
      overlayButtonColor: AppSettings.defaultOverlayButtonColor,
      overlayTargetApp: AppSettings.defaultOverlayTargetApp,
    ));
  }

  Future<void> _resetRulesOverlayDefaults() async {
    _rulesOverlayMessageController.text = '';
    _rulesOverlayButtonTextController.text = '';
    await _save(_settings.copyWith(
      rulesOverlayMessage: AppSettings.defaultRulesOverlayMessage,
      rulesOverlayColor: AppSettings.defaultRulesOverlayColor,
      rulesOverlayButtonText: AppSettings.defaultRulesOverlayButtonText,
      rulesOverlayButtonColor: AppSettings.defaultRulesOverlayButtonColor,
      rulesOverlayTargetApp: AppSettings.defaultRulesOverlayTargetApp,
    ));
  }

  static Color _hexToColor(String hex) {
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return const Color(0xFF000000);
    return Color(value);
  }

  static String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  Future<void> _showColorPickerDialog(
      String title, Color current, ValueChanged<Color> onPicked) async {
    Color picked = current;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: current,
            onColorChanged: (c) => picked = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onPicked(picked);
              Navigator.of(ctx).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  String _targetAppDisplayName(String packageName) {
    if (packageName.isEmpty) return 'Home screen';
    if (InstalledAppsService.instance.isInitialized) {
      return InstalledAppsService.instance.getAppName(packageName);
    }
    return packageName.split('.').last;
  }

  Future<void> _showTargetAppPicker(String currentPackage, ValueChanged<String> onSelected) async {
    if (!InstalledAppsService.instance.isInitialized) {
      await InstalledAppsService.instance.init();
    }
    final apps = List<AppInfo>.from(InstalledAppsService.instance.installedApps)
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Button opens', style: Theme.of(ctx).textTheme.titleMedium),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: apps.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home screen'),
                      trailing: currentPackage.isEmpty ? const Icon(Icons.check) : null,
                      onTap: () {
                        onSelected('');
                        Navigator.of(ctx).pop();
                      },
                    );
                  }
                  final app = apps[index - 1];
                  final isSelected = app.packageName == currentPackage;
                  return ListTile(
                    title: Text(app.name),
                    subtitle: Text(app.packageName, style: Theme.of(ctx).textTheme.bodySmall),
                    trailing: isSelected ? const Icon(Icons.check) : null,
                    onTap: () {
                      onSelected(app.packageName);
                      Navigator.of(ctx).pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _targetAppTile(String label, String packageName, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                Text(
                  _targetAppDisplayName(packageName),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _showTargetAppPicker(packageName, onChanged),
          ),
        ],
      ),
    );
  }

  Widget _colorTile(String label, String hexValue, ValueChanged<String> onChanged) {
    final color = _hexToColor(hexValue);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          GestureDetector(
            onTap: () => _showColorPickerDialog(label, color, (c) {
              onChanged(_colorToHex(c));
            }),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: ListView(
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
                const Divider(),
                _SectionHeader('Coach Overlay'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Message',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _overlayMessageController,
                        decoration: const InputDecoration(
                          hintText:
                              'I detected {app}.\nIt\'s time to focus!',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                        onChanged: (v) => _save(
                            _settings.copyWith(overlayMessage: v)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use {app} for the app name',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Button text',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _overlayButtonTextController,
                        decoration: const InputDecoration(
                          hintText: 'Got it!',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => _save(
                            _settings.copyWith(overlayButtonText: v)),
                      ),
                    ],
                  ),
                ),
                _colorTile(
                  'Background color',
                  _settings.overlayColor,
                  (v) => _save(_settings.copyWith(overlayColor: v)),
                ),
                _colorTile(
                  'Button color',
                  _settings.overlayButtonColor,
                  (v) => _save(_settings.copyWith(overlayButtonColor: v)),
                ),
                _targetAppTile(
                  'Button opens',
                  _settings.overlayTargetApp,
                  (v) => _save(_settings.copyWith(overlayTargetApp: v)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () => FocusService.showOverlay('Preview'),
                    child: const Text('Preview overlay'),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: _resetCoachOverlayDefaults,
                    child: const Text('Reset to defaults'),
                  ),
                ),
                const Divider(),
                _SectionHeader('Rules Overlay'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Message',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _rulesOverlayMessageController,
                        decoration: const InputDecoration(
                          hintText:
                              'I detected {app}.\nIt\'s time to focus!',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        maxLines: 2,
                        onChanged: (v) => _save(
                            _settings.copyWith(rulesOverlayMessage: v)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Use {app} for the app name',
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Button text',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _rulesOverlayButtonTextController,
                        decoration: const InputDecoration(
                          hintText: 'Got it!',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => _save(
                            _settings.copyWith(rulesOverlayButtonText: v)),
                      ),
                    ],
                  ),
                ),
                _colorTile(
                  'Background color',
                  _settings.rulesOverlayColor,
                  (v) => _save(_settings.copyWith(rulesOverlayColor: v)),
                ),
                _colorTile(
                  'Button color',
                  _settings.rulesOverlayButtonColor,
                  (v) => _save(_settings.copyWith(rulesOverlayButtonColor: v)),
                ),
                _targetAppTile(
                  'Button opens',
                  _settings.rulesOverlayTargetApp,
                  (v) => _save(_settings.copyWith(rulesOverlayTargetApp: v)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: () => FocusService.showOverlay('Preview', overlayType: 'rule'),
                    child: const Text('Preview overlay'),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: OutlinedButton(
                    onPressed: _resetRulesOverlayDefaults,
                    child: const Text('Reset to defaults'),
                  ),
                ),
                const Divider(),
                _SectionHeader('Challenge Settings'),
                _SliderTile(
                  title: 'Long press duration',
                  subtitle: 'How long the user must hold to dismiss',
                  value: _settings.longPressDurationSeconds,
                  min: 1,
                  max: 15,
                  divisions: 14,
                  formatLabel: (v) => '${v}s',
                  onChanged: (v) => _save(
                      _settings.copyWith(longPressDurationSeconds: v)),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Typing phrase',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _typingPhraseController,
                        decoration: const InputDecoration(
                          hintText: 'I will focus',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        onChanged: (v) => _save(
                            _settings.copyWith(typingPhrase: v)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
