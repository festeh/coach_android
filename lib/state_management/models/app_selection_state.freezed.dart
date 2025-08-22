// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_selection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AppSelectionState _$AppSelectionStateFromJson(Map<String, dynamic> json) {
  return _AppSelectionState.fromJson(json);
}

/// @nodoc
mixin _$AppSelectionState {
  Set<String> get selectedPackages => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this AppSelectionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSelectionStateCopyWith<AppSelectionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSelectionStateCopyWith<$Res> {
  factory $AppSelectionStateCopyWith(
    AppSelectionState value,
    $Res Function(AppSelectionState) then,
  ) = _$AppSelectionStateCopyWithImpl<$Res, AppSelectionState>;
  @useResult
  $Res call({
    Set<String> selectedPackages,
    bool isLoading,
    String? errorMessage,
  });
}

/// @nodoc
class _$AppSelectionStateCopyWithImpl<$Res, $Val extends AppSelectionState>
    implements $AppSelectionStateCopyWith<$Res> {
  _$AppSelectionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedPackages = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            selectedPackages: null == selectedPackages
                ? _value.selectedPackages
                : selectedPackages // ignore: cast_nullable_to_non_nullable
                      as Set<String>,
            isLoading: null == isLoading
                ? _value.isLoading
                : isLoading // ignore: cast_nullable_to_non_nullable
                      as bool,
            errorMessage: freezed == errorMessage
                ? _value.errorMessage
                : errorMessage // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AppSelectionStateImplCopyWith<$Res>
    implements $AppSelectionStateCopyWith<$Res> {
  factory _$$AppSelectionStateImplCopyWith(
    _$AppSelectionStateImpl value,
    $Res Function(_$AppSelectionStateImpl) then,
  ) = __$$AppSelectionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    Set<String> selectedPackages,
    bool isLoading,
    String? errorMessage,
  });
}

/// @nodoc
class __$$AppSelectionStateImplCopyWithImpl<$Res>
    extends _$AppSelectionStateCopyWithImpl<$Res, _$AppSelectionStateImpl>
    implements _$$AppSelectionStateImplCopyWith<$Res> {
  __$$AppSelectionStateImplCopyWithImpl(
    _$AppSelectionStateImpl _value,
    $Res Function(_$AppSelectionStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AppSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedPackages = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$AppSelectionStateImpl(
        selectedPackages: null == selectedPackages
            ? _value._selectedPackages
            : selectedPackages // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
        isLoading: null == isLoading
            ? _value.isLoading
            : isLoading // ignore: cast_nullable_to_non_nullable
                  as bool,
        errorMessage: freezed == errorMessage
            ? _value.errorMessage
            : errorMessage // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSelectionStateImpl implements _AppSelectionState {
  const _$AppSelectionStateImpl({
    final Set<String> selectedPackages = const {},
    this.isLoading = false,
    this.errorMessage,
  }) : _selectedPackages = selectedPackages;

  factory _$AppSelectionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSelectionStateImplFromJson(json);

  final Set<String> _selectedPackages;
  @override
  @JsonKey()
  Set<String> get selectedPackages {
    if (_selectedPackages is EqualUnmodifiableSetView) return _selectedPackages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedPackages);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'AppSelectionState(selectedPackages: $selectedPackages, isLoading: $isLoading, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSelectionStateImpl &&
            const DeepCollectionEquality().equals(
              other._selectedPackages,
              _selectedPackages,
            ) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_selectedPackages),
    isLoading,
    errorMessage,
  );

  /// Create a copy of AppSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSelectionStateImplCopyWith<_$AppSelectionStateImpl> get copyWith =>
      __$$AppSelectionStateImplCopyWithImpl<_$AppSelectionStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSelectionStateImplToJson(this);
  }
}

abstract class _AppSelectionState implements AppSelectionState {
  const factory _AppSelectionState({
    final Set<String> selectedPackages,
    final bool isLoading,
    final String? errorMessage,
  }) = _$AppSelectionStateImpl;

  factory _AppSelectionState.fromJson(Map<String, dynamic> json) =
      _$AppSelectionStateImpl.fromJson;

  @override
  Set<String> get selectedPackages;
  @override
  bool get isLoading;
  @override
  String? get errorMessage;

  /// Create a copy of AppSelectionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSelectionStateImplCopyWith<_$AppSelectionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
