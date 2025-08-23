import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/focus_data.dart';

part 'focus_state.freezed.dart';
part 'focus_state.g.dart';

@freezed
class FocusState with _$FocusState {
  const factory FocusState({
    @Default(FocusData()) FocusData focusData,
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
