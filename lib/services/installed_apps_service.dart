import 'package:flutter/services.dart';
import '../models/app_info.dart';

class InstalledAppsService {
  static final InstalledAppsService instance = InstalledAppsService._internal();
  static const _platform = MethodChannel('com.example.coach_android/appCount');

  InstalledAppsService._internal();

  List<AppInfo> _installedApps = [];
  Map<String, String> _packageToName = {};
  bool _isInitialized = false;

  List<AppInfo> get installedApps => _installedApps;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final List<dynamic> result = await _platform.invokeMethod('getInstalledApps');
      _installedApps = result
          .cast<Map<dynamic, dynamic>>()
          .map((map) => AppInfo.fromMap(map))
          .toList();

      // Build lookup map
      _packageToName = {
        for (final app in _installedApps) app.packageName: app.name
      };

      _isInitialized = true;
    } on PlatformException catch (e) {
      _installedApps = [];
      _packageToName = {};
      throw Exception('Failed to load installed apps: ${e.message}');
    }
  }

  /// Get app name for a package. Falls back to last part of package name if not found.
  String getAppName(String packageName) {
    return _packageToName[packageName] ?? packageName.split('.').last;
  }
}
