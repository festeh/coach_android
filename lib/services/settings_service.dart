import 'package:shared_preferences/shared_preferences.dart';
import '../constants/storage_keys.dart';
import '../models/app_settings.dart';

class SettingsService {
  static Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final gapSeconds = prefs.getInt(StorageKeys.settingsFocusGapThreshold);
    final cooldownSeconds = prefs.getInt(StorageKeys.settingsReminderCooldown);
    final timeoutSeconds = prefs.getInt(StorageKeys.settingsActivityTimeout);
    final overlayMessage =
        prefs.getString(StorageKeys.settingsOverlayMessage);
    final overlayColor =
        prefs.getString(StorageKeys.settingsOverlayColor);
    final overlayButtonText =
        prefs.getString(StorageKeys.settingsOverlayButtonText);
    final overlayButtonColor =
        prefs.getString(StorageKeys.settingsOverlayButtonColor);
    final rulesOverlayMessage =
        prefs.getString(StorageKeys.settingsRulesOverlayMessage);
    final rulesOverlayColor =
        prefs.getString(StorageKeys.settingsRulesOverlayColor);
    final rulesOverlayButtonText =
        prefs.getString(StorageKeys.settingsRulesOverlayButtonText);
    final rulesOverlayButtonColor =
        prefs.getString(StorageKeys.settingsRulesOverlayButtonColor);
    final overlayTargetApp =
        prefs.getString(StorageKeys.settingsOverlayTargetApp);
    final rulesOverlayTargetApp =
        prefs.getString(StorageKeys.settingsRulesOverlayTargetApp);
    final longPressDuration =
        prefs.getInt(StorageKeys.settingsLongPressDuration);
    final typingPhrase =
        prefs.getString(StorageKeys.settingsTypingPhrase);

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
      overlayMessage: overlayMessage ?? AppSettings.defaultOverlayMessage,
      overlayColor: overlayColor ?? AppSettings.defaultOverlayColor,
      overlayButtonText: overlayButtonText ?? AppSettings.defaultOverlayButtonText,
      overlayButtonColor: overlayButtonColor ?? AppSettings.defaultOverlayButtonColor,
      rulesOverlayMessage: rulesOverlayMessage ?? AppSettings.defaultRulesOverlayMessage,
      rulesOverlayColor: rulesOverlayColor ?? AppSettings.defaultRulesOverlayColor,
      rulesOverlayButtonText: rulesOverlayButtonText ?? AppSettings.defaultRulesOverlayButtonText,
      rulesOverlayButtonColor: rulesOverlayButtonColor ?? AppSettings.defaultRulesOverlayButtonColor,
      overlayTargetApp: overlayTargetApp ?? AppSettings.defaultOverlayTargetApp,
      rulesOverlayTargetApp: rulesOverlayTargetApp ?? AppSettings.defaultRulesOverlayTargetApp,
      longPressDurationSeconds: longPressDuration ?? AppSettings.defaultLongPressDurationSeconds,
      typingPhrase: typingPhrase ?? AppSettings.defaultTypingPhrase,
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
    await prefs.setString(
        StorageKeys.settingsOverlayMessage, settings.overlayMessage);
    await prefs.setString(
        StorageKeys.settingsOverlayColor, settings.overlayColor);
    await prefs.setString(
        StorageKeys.settingsOverlayButtonText, settings.overlayButtonText);
    await prefs.setString(
        StorageKeys.settingsOverlayButtonColor, settings.overlayButtonColor);
    await prefs.setString(
        StorageKeys.settingsRulesOverlayMessage, settings.rulesOverlayMessage);
    await prefs.setString(
        StorageKeys.settingsRulesOverlayColor, settings.rulesOverlayColor);
    await prefs.setString(
        StorageKeys.settingsRulesOverlayButtonText, settings.rulesOverlayButtonText);
    await prefs.setString(
        StorageKeys.settingsRulesOverlayButtonColor, settings.rulesOverlayButtonColor);
    await prefs.setString(
        StorageKeys.settingsOverlayTargetApp, settings.overlayTargetApp);
    await prefs.setString(
        StorageKeys.settingsRulesOverlayTargetApp, settings.rulesOverlayTargetApp);
    await prefs.setInt(
        StorageKeys.settingsLongPressDuration, settings.longPressDurationSeconds);
    await prefs.setString(
        StorageKeys.settingsTypingPhrase, settings.typingPhrase);
  }
}
