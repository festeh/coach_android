import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/focus_service.dart';

final _log = Logger('PermissionsProvider');

class PermissionsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    try {
      return await FocusService.checkUsageStatsPermission();
    } catch (e) {
      _log.severe('Failed to check initial permission: $e');
      rethrow;
    }
  }

  Future<bool> checkAndRequestUsageStatsPermission(BuildContext context) async {
    state = const AsyncLoading();

    bool hasPermission = await FocusService.checkUsageStatsPermission();

    if (!hasPermission && context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Usage Stats Permission Required'),
            content: const Text(
              'This app needs Usage Stats permission to monitor app usage and help you focus. '
              'You will be redirected to Settings to enable this permission.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Grant Permission'),
              ),
            ],
          );
        },
      );

      if (shouldRequest == true) {
        await FocusService.requestUsageStatsPermission();
        hasPermission = await FocusService.checkUsageStatsPermission();
      }
    }

    state = AsyncData(hasPermission);
    return hasPermission;
  }

  Future<void> refreshPermissionStatus() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => FocusService.checkUsageStatsPermission());
  }
}

final permissionsProvider = AsyncNotifierProvider<PermissionsNotifier, bool>(PermissionsNotifier.new);
