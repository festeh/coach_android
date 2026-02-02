import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../models/app_settings.dart';

class SettingsService {
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final gapSeconds = prefs.getInt(StorageKeys.settingsFocusGapThreshold);
    final cooldownSeconds = prefs.getInt(StorageKeys.settingsReminderCooldown);
    final timeoutSeconds = prefs.getInt(StorageKeys.settingsActivityTimeout);

    return AppSettings(
      focusGapThresholdMinutes: gapSeconds != null
          ? gapSeconds ~/ 60
          : AppSettings.defaultFocusGapThresholdMinutes,
      reminderCooldownMinutes: cooldownSeconds != null
          ? cooldownSeconds ~/ 60
          : AppSettings.defaultReminderCooldownMinutes,
      activityTimeoutMinutes: timeoutSeconds != null
          ? timeoutSeconds ~/ 60
          : AppSettings.defaultActivityTimeoutMinutes,
    );
  }

  static Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        StorageKeys.settingsFocusGapThreshold, settings.focusGapThresholdSeconds);
    await prefs.setInt(
        StorageKeys.settingsReminderCooldown, settings.reminderCooldownSeconds);
    await prefs.setInt(
        StorageKeys.settingsActivityTimeout, settings.activityTimeoutSeconds);
  }
}
