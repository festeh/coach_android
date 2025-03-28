
import 'package:shared_preferences/shared_preferences.dart';

class AppState {
  static const _selectedAppsKey = 'selectedApps';

  static Future<Set<String>> loadSelectedApps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_selectedAppsKey)?.toSet() ?? {};
  }

  static Future<void> saveSelectedApps(Set<String> selectedApps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_selectedAppsKey, selectedApps.toList());
  }
}
