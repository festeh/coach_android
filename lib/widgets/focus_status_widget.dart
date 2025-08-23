import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../state_management/models/focus_state.dart';
import '../state_management/providers/focus_provider.dart';
import '../models/log_entry.dart';
import '../services/enhanced_logger.dart';

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
          Text(
            'Status:',
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
                  color: _getStatusColor(context, focusState),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: focusState.status == FocusStatus.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _getFocusStatusText(focusState),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _getStatusTextColor(context, focusState),
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

  Color _getStatusColor(BuildContext context, FocusState state) {
    if (state.status == FocusStatus.error) {
      return Theme.of(context).colorScheme.error;
    }
    if (state.isFocusing) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Theme.of(context).colorScheme.tertiary;
  }

  Color _getStatusTextColor(BuildContext context, FocusState state) {
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
}