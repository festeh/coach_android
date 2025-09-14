import 'package:flutter/material.dart';
import 'package:coach_android/services/focus_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state_management/providers/permissions_provider.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import '../constants/channel_names.dart';

final _log = Logger('DebugView');

class DebugView extends ConsumerStatefulWidget {
  const DebugView({super.key});

  @override
  ConsumerState<DebugView> createState() => _DebugViewState();
}

class _DebugViewState extends ConsumerState<DebugView> with WidgetsBindingObserver {
  bool? _hasUsageStatsPermission;
  bool? _hasOverlayPermission;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, refresh permissions
      _log.info('App resumed, refreshing permissions...');
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final usageStatsPermission = await FocusService.checkUsageStatsPermission();
      final overlayPermission = await FocusService.checkOverlayPermission();

      setState(() {
        _hasUsageStatsPermission = usageStatsPermission;
        _hasOverlayPermission = overlayPermission;
        _isLoading = false;
      });
    } catch (e) {
      _log.warning('Error checking permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceShowFocusReminder(BuildContext context) async {
    _log.info('Debug: Forcing focus reminder notification...');
    final messenger = ScaffoldMessenger.of(context);

    try {
      const methodChannel = MethodChannel(ChannelNames.mainMethods);
      final result = await methodChannel.invokeMethod('forceShowFocusReminder');

      if (mounted) {
        if (result == true) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Focus reminder notification triggered successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          _log.info('Debug: Focus reminder notification triggered successfully');
        } else {
          messenger.showSnackBar(
            SnackBar(
              content: Text('Unexpected result: $result'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          _log.warning('Debug: Unexpected result: $result');
        }
      }
    } catch (e) {
      _log.severe('Debug: Error forcing focus reminder notification: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Debug Console',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            
            // Permissions Section
            _buildSection(
              context,
              'Permissions',
              Icons.security,
              [
                _buildPermissionTile(
                  context,
                  'Usage Stats Permission',
                  _hasUsageStatsPermission,
                  onTap: () async {
                    await ref.read(permissionsProvider.notifier).checkAndRequestUsageStatsPermission(context);
                    await _checkPermissions();
                  },
                ),
                _buildPermissionTile(
                  context,
                  'Overlay Permission',
                  _hasOverlayPermission,
                  onTap: () async {
                    try {
                      await FocusService.requestOverlayPermission();
                      await _checkPermissions();
                    } catch (e) {
                      _log.warning('Error requesting overlay permission: $e');
                    }
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),

            // Notifications Section
            _buildSection(
              context,
              'Notifications',
              Icons.notifications,
              [
                _buildActionButton(
                  context,
                  'Force Focus Reminder',
                  Icons.notification_add,
                  () async {
                    await _forceShowFocusReminder(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Actions Section
            _buildSection(
              context,
              'Actions',
              Icons.build,
              [
                _buildActionButton(
                  context,
                  'Check Usage Stats Permission',
                  Icons.security_outlined,
                  () async {
                    await ref.read(permissionsProvider.notifier).checkAndRequestUsageStatsPermission(context);
                  },
                ),
                _buildActionButton(
                  context,
                  'Request Overlay Permission',
                  Icons.layers_outlined,
                  () async {
                    try {
                      await FocusService.requestOverlayPermission();
                      await _checkPermissions();
                    } catch (e) {
                      _log.warning('Error requesting overlay permission: $e');
                    }
                  },
                ),
                _buildActionButton(
                  context,
                  'Refresh Permission Status',
                  Icons.refresh,
                  () async {
                    await _checkPermissions();
                  },
                ),
                _buildActionButton(
                  context,
                  'Check Service Status',
                  Icons.phone_android,
                  () async {
                    _log.info('Checking service status...');
                    final messenger = ScaffoldMessenger.of(context);
                    try {
                      final isRunning = await FocusService.isServiceRunning();
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Service is ${isRunning ? "running" : "not running"}'),
                            backgroundColor: isRunning ? Colors.green : Colors.orange,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } catch (e) {
                      _log.severe('Error checking service status: $e');
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context,
    String title,
    bool? isGranted, {
    VoidCallback? onTap,
  }) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isGranted == null) {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = 'Unknown';
    } else if (isGranted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Granted';
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
      statusText = 'Denied';
    }

    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: onTap,
              tooltip: 'Request permission',
            ),
          ],
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : onPressed,
          icon: Icon(icon),
          label: Text(title),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}