
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static final ValueNotifier<bool> focusingNotifier = ValueNotifier<bool>(false);

  static const _selectedAppsKey = 'selectedApps';
  static const _focusingKey = 'focusingState';

  static Future<Set<String>> loadSelectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedAppsKey)?.toSet() ?? {};
  }

  static Future<void> saveSelectedApps(Set<String> selectedApps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAppsKey, selectedApps.toList());
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
  }
}
