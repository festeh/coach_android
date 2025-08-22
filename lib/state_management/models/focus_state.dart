import 'package:freezed_annotation/freezed_annotation.dart';

part 'focus_state.freezed.dart';
part 'focus_state.g.dart';

@freezed
class FocusState with _$FocusState {
  const factory FocusState({
    @Default(false) bool isFocusing,
    @Default(0) int numFocuses,
    @Default(0.0) double focusTimeLeft,
    @Default(FocusStatus.loading) FocusStatus status,
    String? errorMessage,
  }) = _FocusState;

  factory FocusState.fromJson(Map<String, dynamic> json) =>
      _$FocusStateFromJson(json);
}

enum FocusStatus {
  loading,
  ready,
  error,
}