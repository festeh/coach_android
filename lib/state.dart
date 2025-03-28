import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('AppState');

class AppState {
  static final ValueNotifier<bool> focusingNotifier = ValueNotifier<bool>(
    false,
  );

  // Store selected package names now
  static const _selectedAppPackagesKey = 'selectedAppPackages';
  static const _focusingKey = 'focusingState';

  // Returns a set of selected package names
  static Future<Set<String>> loadSelectedAppPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedAppPackagesKey)?.toSet() ?? {};
  }

  static Future<void> saveSelectedApps(Set<String> selectedApps) async {
    final prefs = await SharedPreferences.getInstance();
    // Save selected package names
    await prefs.setStringList(_selectedAppPackagesKey, selectedApps.toList());
    _log.info('Saved selected app packages: ${selectedApps.length}');
  }

  static Future<bool> loadFocusingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isFocusing = prefs.getBool(_focusingKey) ?? false;
    focusingNotifier.value = isFocusing;
    return isFocusing;
  }

  static Future<void> saveFocusingState(bool isFocusing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusingKey, isFocusing);
    focusingNotifier.value = isFocusing;
    _log.info('Saved focusing state: $isFocusing');
  }
}
