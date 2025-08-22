import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

final _log = Logger('StateService');

class StateService {
  static const _selectedAppPackagesKey = 'selectedAppPackages';
  static const _focusingKey = 'focusingState';

  Future<Set<String>> loadSelectedAppPackages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packages = prefs.getStringList(_selectedAppPackagesKey) ?? [];
      _log.info('Loaded ${packages.length} selected app packages');
      return packages.toSet();
    } catch (e) {
      _log.severe('Error loading selected app packages: $e');
      return {};
    }
  }

  Future<void> saveSelectedApps(Set<String> selectedApps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_selectedAppPackagesKey, selectedApps.toList());
      _log.info('Saved ${selectedApps.length} selected app packages');
    } catch (e) {
      _log.severe('Error saving selected app packages: $e');
      rethrow;
    }
  }

  Future<bool?> loadFocusingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFocusing = prefs.getBool(_focusingKey);
      _log.info('Loaded focusing state: $isFocusing');
      return isFocusing;
    } catch (e) {
      _log.severe('Error loading focusing state: $e');
      return null;
    }
  }

  Future<void> saveFocusingState(bool isFocusing) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_focusingKey, isFocusing);
      _log.info('Saved focusing state: $isFocusing');
    } catch (e) {
      _log.severe('Error saving focusing state: $e');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedAppPackagesKey);
      await prefs.remove(_focusingKey);
      _log.info('Cleared all state data');
    } catch (e) {
      _log.severe('Error clearing state data: $e');
      rethrow;
    }
  }
}