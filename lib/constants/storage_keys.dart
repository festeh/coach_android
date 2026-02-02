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

  // Overlay appearance keys
  static const String settingsOverlayMessage = 'settingsOverlayMessage';
  static const String settingsOverlayColor = 'settingsOverlayColor';
  static const String settingsOverlayButtonText = 'settingsOverlayButtonText';
  static const String settingsOverlayButtonColor = 'settingsOverlayButtonColor';
}