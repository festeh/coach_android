import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../../services/focus_service.dart';

final _log = Logger('PermissionsProvider');

class PermissionsState {
  final bool hasUsageStatsPermission;
  final bool isCheckingPermission;
  final String? errorMessage;

  const PermissionsState({
    this.hasUsageStatsPermission = false,
    this.isCheckingPermission = false,
    this.errorMessage,
  });

  PermissionsState copyWith({
    bool? hasUsageStatsPermission,
    bool? isCheckingPermission,
    String? errorMessage,
  }) {
    return PermissionsState(
      hasUsageStatsPermission: hasUsageStatsPermission ?? this.hasUsageStatsPermission,
      isCheckingPermission: isCheckingPermission ?? this.isCheckingPermission,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class PermissionsNotifier extends StateNotifier<PermissionsState> {
  PermissionsNotifier() : super(const PermissionsState()) {
    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    state = state.copyWith(isCheckingPermission: true);
    try {
      final hasPermission = await FocusService.checkUsageStatsPermission();
      state = state.copyWith(
        hasUsageStatsPermission: hasPermission,
        isCheckingPermission: false,
        errorMessage: null,
      );
    } catch (e) {
      _log.severe('Failed to check initial permission: $e');
      state = state.copyWith(
        isCheckingPermission: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<bool> checkAndRequestUsageStatsPermission(BuildContext context) async {
    state = state.copyWith(isCheckingPermission: true);
    
    bool hasPermission = await FocusService.checkUsageStatsPermission();

    if (!hasPermission && context.mounted) {
      // Show dialog to request permission
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
        // Check again after user returns from settings
        hasPermission = await FocusService.checkUsageStatsPermission();
      }
    }

    state = state.copyWith(
      hasUsageStatsPermission: hasPermission,
      isCheckingPermission: false,
    );

    return hasPermission;
  }

  Future<void> refreshPermissionStatus() async {
    await _checkInitialPermission();
  }
}

final permissionsProvider = StateNotifierProvider<PermissionsNotifier, PermissionsState>((ref) {
  return PermissionsNotifier();
});