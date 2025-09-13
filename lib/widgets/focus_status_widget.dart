import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter/services.dart';
import '../state_management/models/focus_state.dart';
import '../state_management/providers/focus_provider.dart';
import '../models/log_entry.dart';
import '../services/enhanced_logger.dart';
import '../constants/channel_names.dart';

final _log = Logger('FocusStatusWidget');

class FocusStatusWidget extends ConsumerWidget {
  const FocusStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusState = ref.watch(focusStateProvider);
    
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
          // Show Focus button when not focusing, otherwise show status
          if (!focusState.focusData.isFocusing && focusState.status != FocusStatus.loading)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _sendFocusCommand(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Focus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_getFocusCountText(focusState).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getFocusCountText(focusState),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            // Show status when focusing or loading (centered, no "Status:" label)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, focusState),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: focusState.status == FocusStatus.loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _getFocusStatusText(focusState),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusTextColor(context, focusState),
                            ),
                          ),
                  ),
                  if (_getFocusCountText(focusState).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _getFocusCountText(focusState),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                ],
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
    );
  }

  Color _getStatusColor(BuildContext context, FocusState state) {
    if (state.status == FocusStatus.error) {
      return Theme.of(context).colorScheme.error;
    }
    if (state.focusData.isFocusing) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Theme.of(context).colorScheme.tertiary;
  }

  Color _getStatusTextColor(BuildContext context, FocusState state) {
    if (state.status == FocusStatus.error) {
      return Theme.of(context).colorScheme.onError;
    }
    if (state.focusData.isFocusing) {
      return Theme.of(context).colorScheme.onSecondary;
    }
    return Theme.of(context).colorScheme.onTertiary;
  }

  String _getFocusCountText(FocusState state) {
    final count = state.focusData.numFocuses;
    if (state.focusData.isFocusing && count > 0) {
      return 'Focus #$count today';
    } else if (count > 0) {
      return '$count completed today';
    }
    return '';
  }

  String _getFocusStatusText(FocusState state) {
    if (state.status == FocusStatus.loading) {
      return 'Loading...';
    }
    if (state.status == FocusStatus.error) {
      return 'Error';
    }
    if (state.focusData.isFocusing) {
      if (state.focusData.focusTimeLeft > 0) {
        // focusTimeLeft is in seconds, convert to minutes and round to natural number
        final minutes = (state.focusData.focusTimeLeft / 60).round();
        if (minutes > 0) {
          return '$minutes min remaining';
        } else {
          // Less than 30 seconds left, show seconds
          final seconds = state.focusData.focusTimeLeft;
          return '${seconds}s remaining';
        }
      }
      return 'Focusing';
    }
    return 'Not Focusing';
  }

  Future<void> _sendFocusCommand(BuildContext context, WidgetRef ref) async {
    _log.info('User tapped Focus button');
    
    EnhancedLogger.info(
      LogSource.ui,
      LogCategory.user,
      'Focus command requested by user',
    );

    try {
      // Send focus command via method channel to native service
      const methodChannel = MethodChannel(ChannelNames.mainMethods);
      await methodChannel.invokeMethod('sendFocusCommand');
      
      _log.info('Focus command sent successfully');
      
      EnhancedLogger.info(
        LogSource.ui,
        LogCategory.user,
        'Focus command sent successfully',
      );
      
      // Optionally trigger a refresh to get updated status
      if (context.mounted) {
        ref.read(focusStateProvider.notifier).forceFetch();
      }
    } catch (e) {
      _log.severe('Failed to send focus command: $e');
      
      EnhancedLogger.error(
        LogSource.ui,
        LogCategory.user,
        'Failed to send focus command',
        {'error': e.toString()},
      );
      
      // Show error to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send focus command: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}