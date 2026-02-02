/// Shared storage keys used by both UI and background engines
/// to ensure consistent data access across isolates
class StorageKeys {
  // App selection keys
  static const String selectedAppPackages = 'selectedAppPackages';
  
  // Focus state keys
  static const String focusingState = 'focusingState';

  // Settings keys (values stored in seconds)
  static const String settingsFocusGapThreshold = 'settingsFocusGapThreshold';
  static const String settingsReminderCooldown = 'settingsReminderCooldown';
  static const String settingsActivityTimeout = 'settingsActivityTimeout';

  // Coach overlay appearance keys
  static const String settingsOverlayMessage = 'settingsOverlayMessage';
  static const String settingsOverlayColor = 'settingsOverlayColor';
  static const String settingsOverlayButtonText = 'settingsOverlayButtonText';
  static const String settingsOverlayButtonColor = 'settingsOverlayButtonColor';

  // App rules
  static const String appRules = 'appRules';

  // Rules overlay appearance keys
  static const String settingsRulesOverlayMessage = 'settingsRulesOverlayMessage';
  static const String settingsRulesOverlayColor = 'settingsRulesOverlayColor';
  static const String settingsRulesOverlayButtonText = 'settingsRulesOverlayButtonText';
  static const String settingsRulesOverlayButtonColor = 'settingsRulesOverlayButtonColor';

  // Overlay target app (package name to open on button press, empty = home screen)
  static const String settingsOverlayTargetApp = 'settingsOverlayTargetApp';
  static const String settingsRulesOverlayTargetApp = 'settingsRulesOverlayTargetApp';

  // Challenge settings
  static const String settingsLongPressDuration = 'settingsLongPressDuration';
  static const String settingsTypingPhrase = 'settingsTypingPhrase';

  // Pending challenges (JSON array of rule IDs)
  static const String pendingChallenges = 'pendingChallenges';
}