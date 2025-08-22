import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'dart:async';
import 'package:logging/logging.dart';
import 'models/app_info.dart';
import 'models/log_entry.dart';
import 'services/enhanced_logger.dart';
import 'app_monitor.dart';
import 'state_management/providers/focus_provider.dart';
import 'state_management/providers/app_selection_provider.dart';
import 'state_management/models/app_selection_state.dart';
import 'state_management/models/focus_state.dart';
import 'state_management/services/background_service_interface.dart';

final _log = Logger('AppsView');

class AppsView extends ConsumerStatefulWidget {
  const AppsView({super.key});

  @override
  ConsumerState<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends ConsumerState<AppsView> {
  static const platform = MethodChannel('com.example.coach_android/appCount');
  List<AppInfo> _installedApps = [];
  bool _isLoading = true;
  StreamSubscription<Map<String, dynamic>?>? _focusingStateSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize background service interface with ref
    BackgroundServiceManager.initializeForWidget(ref);
    _loadInstalledApps();
    _listenForFocusingUpdates();
    _checkPermissions();
  }

  @override
  void dispose() {
    _focusingStateSubscription?.cancel();
    BackgroundServiceManager.dispose();
    super.dispose();
  }

  void _listenForFocusingUpdates() {
    _focusingStateSubscription = FlutterBackgroundService()
        .on('updateFocusingState')
        .listen((event) {
          if (event != null) {
            _log.info('Received focusing update from background: $event');
            // Update the focus state through the provider
            ref.read(focusStateProvider.notifier).updateFromWebSocket(event);
          }
        });
  }

  Future<void> _checkPermissions() async {
    // Small delay to ensure UI is fully loaded before showing dialog
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      await checkAndRequestUsageStatsPermission(context);
    }
  }

  Future<void> _loadInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      if (mounted) {
        setState(() {
          _installedApps = result
              .cast<Map<dynamic, dynamic>>()
              .map((map) => AppInfo.fromMap(map))
              .toList();
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _installedApps = [];
          _isLoading = false;
        });
      }
      debugPrint("Failed to get installed apps: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final focusState = ref.watch(focusStateProvider);
    final appSelection = ref.watch(appSelectionProvider);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(focusState, appSelection),
    );
  }

  Widget _buildContent(FocusState focusState, AppSelectionState appSelection) {
    return Column(
      children: [
        _buildFocusStatusCard(focusState),
        _buildAppCount(),
        Expanded(
          child: _buildAppList(appSelection),
        ),
      ],
    );
  }

  Widget _buildFocusStatusCard(FocusState focusState) {
    final text = _getFocusStatusText(focusState);
    final isLoading = focusState.status == FocusStatus.loading;
    
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Focusing Status:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(focusState),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getStatusTextColor(focusState),
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              Material(
                shape: const CircleBorder(),
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _log.info('User tapped refresh button for focus status');
                    EnhancedLogger.info(
                      LogSource.ui,
                      LogCategory.user,
                      'Focus status refresh requested by user',
                    );
                    ref.read(focusStateProvider.notifier).forceFetch();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(FocusState state) {
    if (state.status == FocusStatus.error) {
      return Theme.of(context).colorScheme.error;
    }
    if (state.isFocusing) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Theme.of(context).colorScheme.tertiary;
  }

  Color _getStatusTextColor(FocusState state) {
    if (state.status == FocusStatus.error) {
      return Theme.of(context).colorScheme.onError;
    }
    if (state.isFocusing) {
      return Theme.of(context).colorScheme.onSecondary;
    }
    return Theme.of(context).colorScheme.onTertiary;
  }

  String _getFocusStatusText(FocusState state) {
    if (state.status == FocusStatus.loading) {
      return 'Loading...';
    }
    if (state.status == FocusStatus.error) {
      return 'Error';
    }
    if (state.isFocusing) {
      if (state.focusTimeLeft > 0) {
        return 'Focusing (${state.focusTimeLeft.toStringAsFixed(1)} min)';
      }
      return 'Focusing';
    }
    return 'Not Focusing';
  }

  Widget _buildAppCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'Total Apps: ${_installedApps.length}',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildAppList(AppSelectionState appSelection) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      itemCount: _installedApps.length,
      itemBuilder: (context, index) {
        final app = _installedApps[index];
        final isSelected = appSelection.selectedPackages.contains(app.packageName);
        
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: ListTile(
            title: Text(
              app.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () {
                ref.read(appSelectionProvider.notifier).toggleApp(app.packageName);
              },
            ),
          ),
        );
      },
    );
  }
}