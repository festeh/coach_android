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
  }) = _FocusData;

  factory FocusData.fromJson(Map<String, dynamic> json) =>
      _$FocusDataFromJson(json);

  factory FocusData.fromWebSocketResponse(Map<String, dynamic> data) {
    return FocusData(
      isFocusing: data['focusing'] as bool? ?? false,
      sinceLastChange: data['since_last_change'] as int? ?? 0,
      focusTimeLeft: data['focus_time_left'] as int? ?? 0,
      numFocuses: data['num_focuses'] as int? ?? 0,
    );
  }

  factory FocusData.fromSharedPreferences({
    required bool isFocusing,
    required int sinceLastChange,
    required int focusTimeLeft,
    required int numFocuses,
  }) {
    return FocusData(
      isFocusing: isFocusing,
      sinceLastChange: sinceLastChange,
      focusTimeLeft: focusTimeLeft,
      numFocuses: numFocuses,
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
    };
  }

  /// Convert to Map for method channel communication
  Map<String, dynamic> toMethodChannelMap() {
    return {
      'focusing': isFocusing,
      'sinceLastChange': sinceLastChange,
      'focusTimeLeft': focusTimeLeft,
      'numFocuses': numFocuses,
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
    return copyWith(
      isFocusing: data['focusing'] as bool? ?? isFocusing,
      sinceLastChange: data['since_last_change'] as int? ?? sinceLastChange,
      focusTimeLeft: data['focus_time_left'] as int? ?? focusTimeLeft,
      numFocuses: data['num_focuses'] as int? ?? numFocuses,
    );
  }
}

