import 'package:freezed_annotation/freezed_annotation.dart';

part 'focus_data.freezed.dart';
part 'focus_data.g.dart';

@freezed
class FocusData with _$FocusData {
  const factory FocusData({
    @Default(false) bool isFocusing,
    @Default(0) int sinceLastChange,
    @Default(0) int focusTimeLeft,
    @Default(0) int numFocuses,
    @Default(0) int lastNotificationTime, // Unix timestamp in seconds
    @Default(0) int lastActivityTime, // Unix timestamp in seconds
    @Default(0) int lastFocusEndTime, // Unix timestamp in seconds
  }) = _FocusData;

  factory FocusData.fromJson(Map<String, dynamic> json) =>
      _$FocusDataFromJson(json);

  factory FocusData.fromWebSocketResponse(Map<String, dynamic> data, {
    int lastNotificationTime = 0,
    int lastActivityTime = 0,
    int lastFocusEndTime = 0,
  }) {
    return FocusData(
      isFocusing: data['focusing'] as bool? ?? false,
      sinceLastChange: data['since_last_change'] as int? ?? 0,
      focusTimeLeft: data['focus_time_left'] as int? ?? 0,
      numFocuses: data['num_focuses'] as int? ?? 0,
      lastNotificationTime: lastNotificationTime,
      lastActivityTime: lastActivityTime,
      lastFocusEndTime: lastFocusEndTime,
    );
  }

  factory FocusData.fromSharedPreferences({
    required bool isFocusing,
    required int sinceLastChange,
    required int focusTimeLeft,
    required int numFocuses,
    int lastNotificationTime = 0,
    int lastActivityTime = 0,
    int lastFocusEndTime = 0,
  }) {
    return FocusData(
      isFocusing: isFocusing,
      sinceLastChange: sinceLastChange,
      focusTimeLeft: focusTimeLeft,
      numFocuses: numFocuses,
      lastNotificationTime: lastNotificationTime,
      lastActivityTime: lastActivityTime,
      lastFocusEndTime: lastFocusEndTime,
    );
  }
}

extension FocusDataMethods on FocusData {
  /// Convert to Map for SharedPreferences storage
  Map<String, dynamic> toSharedPreferencesMap() {
    return {
      'focusing': isFocusing,
      'sinceLastChange': sinceLastChange,
      'focusTimeLeft': focusTimeLeft,
      'numFocuses': numFocuses,
      'lastNotificationTime': lastNotificationTime,
      'lastActivityTime': lastActivityTime,
      'lastFocusEndTime': lastFocusEndTime,
    };
  }

  /// Convert to Map for method channel communication
  Map<String, dynamic> toMethodChannelMap() {
    return {
      'focusing': isFocusing,
      'sinceLastChange': sinceLastChange,
      'focusTimeLeft': focusTimeLeft,
      'numFocuses': numFocuses,
      'lastNotificationTime': lastNotificationTime,
      'lastActivityTime': lastActivityTime,
      'lastFocusEndTime': lastFocusEndTime,
    };
  }

  /// Check if any meaningful data has changed (used for state updates)
  bool hasSignificantDifference(FocusData other) {
    return isFocusing != other.isFocusing ||
        (sinceLastChange - other.sinceLastChange).abs() >
            10 || // More than 10 seconds difference
        (focusTimeLeft - other.focusTimeLeft).abs() >
            30 || // More than 30 seconds difference
        numFocuses != other.numFocuses;
  }

  /// Create a copy with updated values from WebSocket data
  FocusData updateFromWebSocket(Map<String, dynamic> data) {
    final wasNotFocusing = !isFocusing;
    final nowFocusing = data['focusing'] as bool? ?? isFocusing;
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // If we were focusing and now we're not, update lastFocusEndTime
    final newLastFocusEndTime = (isFocusing && !nowFocusing) ? currentTime : lastFocusEndTime;

    return copyWith(
      isFocusing: nowFocusing,
      sinceLastChange: data['since_last_change'] as int? ?? sinceLastChange,
      focusTimeLeft: data['focus_time_left'] as int? ?? focusTimeLeft,
      numFocuses: data['num_focuses'] as int? ?? numFocuses,
      lastFocusEndTime: newLastFocusEndTime,
    );
  }
}

