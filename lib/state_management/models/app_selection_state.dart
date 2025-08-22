import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_selection_state.freezed.dart';
part 'app_selection_state.g.dart';

@freezed
class AppSelectionState with _$AppSelectionState {
  const factory AppSelectionState({
    @Default({}) Set<String> selectedPackages,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _AppSelectionState;

  factory AppSelectionState.fromJson(Map<String, dynamic> json) =>
      _$AppSelectionStateFromJson(json);
}