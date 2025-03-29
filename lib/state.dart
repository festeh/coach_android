import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger('AppState');

enum FocusingState { loading, focusing, notFocusing, errorNoSuchKey }

class AppState {
  static final ValueNotifier<FocusingState> focusingNotifier =
      ValueNotifier<FocusingState>(FocusingState.loading);

  static const _selectedAppPackagesKey = 'selectedAppPackages';
  static const _focusingKey = 'focusingState';

  static Future<Set<String>> loadSelectedAppPackages() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedAppPackagesKey)?.toSet() ?? {};
  }

  static Future<void> saveSelectedApps(Set<String> selectedApps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAppPackagesKey, selectedApps.toList());
    _log.info('Saved selected app packages: ${selectedApps.length}');
  }

  static void updateFocusingState(bool isFocusing) {
    _log.info('Updating focusing state: $isFocusing');
    focusingNotifier.value =
        isFocusing ? FocusingState.focusing : FocusingState.notFocusing;
  }

  static Future<bool> loadFocusingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isFocusing = prefs.getBool(_focusingKey);
    if (isFocusing == null) {
      focusingNotifier.value = FocusingState.errorNoSuchKey;
      return false;
    }
    updateFocusingState(isFocusing);
    return isFocusing;
  }

  static Future<void> saveFocusingState(bool isFocusing) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_focusingKey, isFocusing);
    // Remove the direct notifier update from here - UI will load it.
    _log.info('Saved focusing state: $isFocusing');
  }
}
