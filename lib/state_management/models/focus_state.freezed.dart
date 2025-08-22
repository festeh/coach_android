// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FocusState _$FocusStateFromJson(Map<String, dynamic> json) {
  return _FocusState.fromJson(json);
}

/// @nodoc
mixin _$FocusState {
  bool get isFocusing => throw _privateConstructorUsedError;
  int get numFocuses => throw _privateConstructorUsedError;
  double get focusTimeLeft => throw _privateConstructorUsedError;
  FocusStatus get status => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this FocusState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FocusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FocusStateCopyWith<FocusState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FocusStateCopyWith<$Res> {
  factory $FocusStateCopyWith(
    FocusState value,
    $Res Function(FocusState) then,
  ) = _$FocusStateCopyWithImpl<$Res, FocusState>;
  @useResult
  $Res call({
    bool isFocusing,
    int numFocuses,
    double focusTimeLeft,
    FocusStatus status,
    String? errorMessage,
  });
}

/// @nodoc
class _$FocusStateCopyWithImpl<$Res, $Val extends FocusState>
    implements $FocusStateCopyWith<$Res> {
  _$FocusStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FocusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFocusing = null,
    Object? numFocuses = null,
    Object? focusTimeLeft = null,
    Object? status = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _value.copyWith(
            isFocusing: null == isFocusing
                ? _value.isFocusing
                : isFocusing // ignore: cast_nullable_to_non_nullable
                      as bool,
            numFocuses: null == numFocuses
                ? _value.numFocuses
                : numFocuses // ignore: cast_nullable_to_non_nullable
                      as int,
            focusTimeLeft: null == focusTimeLeft
                ? _value.focusTimeLeft
                : focusTimeLeft // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as FocusStatus,
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
abstract class _$$FocusStateImplCopyWith<$Res>
    implements $FocusStateCopyWith<$Res> {
  factory _$$FocusStateImplCopyWith(
    _$FocusStateImpl value,
    $Res Function(_$FocusStateImpl) then,
  ) = __$$FocusStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isFocusing,
    int numFocuses,
    double focusTimeLeft,
    FocusStatus status,
    String? errorMessage,
  });
}

/// @nodoc
class __$$FocusStateImplCopyWithImpl<$Res>
    extends _$FocusStateCopyWithImpl<$Res, _$FocusStateImpl>
    implements _$$FocusStateImplCopyWith<$Res> {
  __$$FocusStateImplCopyWithImpl(
    _$FocusStateImpl _value,
    $Res Function(_$FocusStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FocusState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFocusing = null,
    Object? numFocuses = null,
    Object? focusTimeLeft = null,
    Object? status = null,
    Object? errorMessage = freezed,
  }) {
    return _then(
      _$FocusStateImpl(
        isFocusing: null == isFocusing
            ? _value.isFocusing
            : isFocusing // ignore: cast_nullable_to_non_nullable
                  as bool,
        numFocuses: null == numFocuses
            ? _value.numFocuses
            : numFocuses // ignore: cast_nullable_to_non_nullable
                  as int,
        focusTimeLeft: null == focusTimeLeft
            ? _value.focusTimeLeft
            : focusTimeLeft // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as FocusStatus,
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
class _$FocusStateImpl implements _FocusState {
  const _$FocusStateImpl({
    this.isFocusing = false,
    this.numFocuses = 0,
    this.focusTimeLeft = 0.0,
    this.status = FocusStatus.loading,
    this.errorMessage,
  });

  factory _$FocusStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$FocusStateImplFromJson(json);

  @override
  @JsonKey()
  final bool isFocusing;
  @override
  @JsonKey()
  final int numFocuses;
  @override
  @JsonKey()
  final double focusTimeLeft;
  @override
  @JsonKey()
  final FocusStatus status;
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'FocusState(isFocusing: $isFocusing, numFocuses: $numFocuses, focusTimeLeft: $focusTimeLeft, status: $status, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FocusStateImpl &&
            (identical(other.isFocusing, isFocusing) ||
                other.isFocusing == isFocusing) &&
            (identical(other.numFocuses, numFocuses) ||
                other.numFocuses == numFocuses) &&
            (identical(other.focusTimeLeft, focusTimeLeft) ||
                other.focusTimeLeft == focusTimeLeft) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isFocusing,
    numFocuses,
    focusTimeLeft,
    status,
    errorMessage,
  );

  /// Create a copy of FocusState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FocusStateImplCopyWith<_$FocusStateImpl> get copyWith =>
      __$$FocusStateImplCopyWithImpl<_$FocusStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FocusStateImplToJson(this);
  }
}

abstract class _FocusState implements FocusState {
  const factory _FocusState({
    final bool isFocusing,
    final int numFocuses,
    final double focusTimeLeft,
    final FocusStatus status,
    final String? errorMessage,
  }) = _$FocusStateImpl;

  factory _FocusState.fromJson(Map<String, dynamic> json) =
      _$FocusStateImpl.fromJson;

  @override
  bool get isFocusing;
  @override
  int get numFocuses;
  @override
  double get focusTimeLeft;
  @override
  FocusStatus get status;
  @override
  String? get errorMessage;

  /// Create a copy of FocusState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FocusStateImplCopyWith<_$FocusStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
