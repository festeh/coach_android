// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FocusData _$FocusDataFromJson(Map<String, dynamic> json) {
  return _FocusData.fromJson(json);
}

/// @nodoc
mixin _$FocusData {
  bool get isFocusing => throw _privateConstructorUsedError;
  int get sinceLastChange => throw _privateConstructorUsedError;
  int get focusTimeLeft => throw _privateConstructorUsedError;
  int get numFocuses => throw _privateConstructorUsedError;
  int get lastNotificationTime =>
      throw _privateConstructorUsedError; // Unix timestamp in seconds
  int get lastActivityTime =>
      throw _privateConstructorUsedError; // Unix timestamp in seconds
  int get lastFocusEndTime => throw _privateConstructorUsedError;

  /// Serializes this FocusData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FocusData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FocusDataCopyWith<FocusData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FocusDataCopyWith<$Res> {
  factory $FocusDataCopyWith(FocusData value, $Res Function(FocusData) then) =
      _$FocusDataCopyWithImpl<$Res, FocusData>;
  @useResult
  $Res call({
    bool isFocusing,
    int sinceLastChange,
    int focusTimeLeft,
    int numFocuses,
    int lastNotificationTime,
    int lastActivityTime,
    int lastFocusEndTime,
  });
}

/// @nodoc
class _$FocusDataCopyWithImpl<$Res, $Val extends FocusData>
    implements $FocusDataCopyWith<$Res> {
  _$FocusDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FocusData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFocusing = null,
    Object? sinceLastChange = null,
    Object? focusTimeLeft = null,
    Object? numFocuses = null,
    Object? lastNotificationTime = null,
    Object? lastActivityTime = null,
    Object? lastFocusEndTime = null,
  }) {
    return _then(
      _value.copyWith(
            isFocusing: null == isFocusing
                ? _value.isFocusing
                : isFocusing // ignore: cast_nullable_to_non_nullable
                      as bool,
            sinceLastChange: null == sinceLastChange
                ? _value.sinceLastChange
                : sinceLastChange // ignore: cast_nullable_to_non_nullable
                      as int,
            focusTimeLeft: null == focusTimeLeft
                ? _value.focusTimeLeft
                : focusTimeLeft // ignore: cast_nullable_to_non_nullable
                      as int,
            numFocuses: null == numFocuses
                ? _value.numFocuses
                : numFocuses // ignore: cast_nullable_to_non_nullable
                      as int,
            lastNotificationTime: null == lastNotificationTime
                ? _value.lastNotificationTime
                : lastNotificationTime // ignore: cast_nullable_to_non_nullable
                      as int,
            lastActivityTime: null == lastActivityTime
                ? _value.lastActivityTime
                : lastActivityTime // ignore: cast_nullable_to_non_nullable
                      as int,
            lastFocusEndTime: null == lastFocusEndTime
                ? _value.lastFocusEndTime
                : lastFocusEndTime // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FocusDataImplCopyWith<$Res>
    implements $FocusDataCopyWith<$Res> {
  factory _$$FocusDataImplCopyWith(
    _$FocusDataImpl value,
    $Res Function(_$FocusDataImpl) then,
  ) = __$$FocusDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isFocusing,
    int sinceLastChange,
    int focusTimeLeft,
    int numFocuses,
    int lastNotificationTime,
    int lastActivityTime,
    int lastFocusEndTime,
  });
}

/// @nodoc
class __$$FocusDataImplCopyWithImpl<$Res>
    extends _$FocusDataCopyWithImpl<$Res, _$FocusDataImpl>
    implements _$$FocusDataImplCopyWith<$Res> {
  __$$FocusDataImplCopyWithImpl(
    _$FocusDataImpl _value,
    $Res Function(_$FocusDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FocusData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isFocusing = null,
    Object? sinceLastChange = null,
    Object? focusTimeLeft = null,
    Object? numFocuses = null,
    Object? lastNotificationTime = null,
    Object? lastActivityTime = null,
    Object? lastFocusEndTime = null,
  }) {
    return _then(
      _$FocusDataImpl(
        isFocusing: null == isFocusing
            ? _value.isFocusing
            : isFocusing // ignore: cast_nullable_to_non_nullable
                  as bool,
        sinceLastChange: null == sinceLastChange
            ? _value.sinceLastChange
            : sinceLastChange // ignore: cast_nullable_to_non_nullable
                  as int,
        focusTimeLeft: null == focusTimeLeft
            ? _value.focusTimeLeft
            : focusTimeLeft // ignore: cast_nullable_to_non_nullable
                  as int,
        numFocuses: null == numFocuses
            ? _value.numFocuses
            : numFocuses // ignore: cast_nullable_to_non_nullable
                  as int,
        lastNotificationTime: null == lastNotificationTime
            ? _value.lastNotificationTime
            : lastNotificationTime // ignore: cast_nullable_to_non_nullable
                  as int,
        lastActivityTime: null == lastActivityTime
            ? _value.lastActivityTime
            : lastActivityTime // ignore: cast_nullable_to_non_nullable
                  as int,
        lastFocusEndTime: null == lastFocusEndTime
            ? _value.lastFocusEndTime
            : lastFocusEndTime // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FocusDataImpl implements _FocusData {
  const _$FocusDataImpl({
    this.isFocusing = false,
    this.sinceLastChange = 0,
    this.focusTimeLeft = 0,
    this.numFocuses = 0,
    this.lastNotificationTime = 0,
    this.lastActivityTime = 0,
    this.lastFocusEndTime = 0,
  });

  factory _$FocusDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FocusDataImplFromJson(json);

  @override
  @JsonKey()
  final bool isFocusing;
  @override
  @JsonKey()
  final int sinceLastChange;
  @override
  @JsonKey()
  final int focusTimeLeft;
  @override
  @JsonKey()
  final int numFocuses;
  @override
  @JsonKey()
  final int lastNotificationTime;
  // Unix timestamp in seconds
  @override
  @JsonKey()
  final int lastActivityTime;
  // Unix timestamp in seconds
  @override
  @JsonKey()
  final int lastFocusEndTime;

  @override
  String toString() {
    return 'FocusData(isFocusing: $isFocusing, sinceLastChange: $sinceLastChange, focusTimeLeft: $focusTimeLeft, numFocuses: $numFocuses, lastNotificationTime: $lastNotificationTime, lastActivityTime: $lastActivityTime, lastFocusEndTime: $lastFocusEndTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FocusDataImpl &&
            (identical(other.isFocusing, isFocusing) ||
                other.isFocusing == isFocusing) &&
            (identical(other.sinceLastChange, sinceLastChange) ||
                other.sinceLastChange == sinceLastChange) &&
            (identical(other.focusTimeLeft, focusTimeLeft) ||
                other.focusTimeLeft == focusTimeLeft) &&
            (identical(other.numFocuses, numFocuses) ||
                other.numFocuses == numFocuses) &&
            (identical(other.lastNotificationTime, lastNotificationTime) ||
                other.lastNotificationTime == lastNotificationTime) &&
            (identical(other.lastActivityTime, lastActivityTime) ||
                other.lastActivityTime == lastActivityTime) &&
            (identical(other.lastFocusEndTime, lastFocusEndTime) ||
                other.lastFocusEndTime == lastFocusEndTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isFocusing,
    sinceLastChange,
    focusTimeLeft,
    numFocuses,
    lastNotificationTime,
    lastActivityTime,
    lastFocusEndTime,
  );

  /// Create a copy of FocusData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FocusDataImplCopyWith<_$FocusDataImpl> get copyWith =>
      __$$FocusDataImplCopyWithImpl<_$FocusDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FocusDataImplToJson(this);
  }
}

abstract class _FocusData implements FocusData {
  const factory _FocusData({
    final bool isFocusing,
    final int sinceLastChange,
    final int focusTimeLeft,
    final int numFocuses,
    final int lastNotificationTime,
    final int lastActivityTime,
    final int lastFocusEndTime,
  }) = _$FocusDataImpl;

  factory _FocusData.fromJson(Map<String, dynamic> json) =
      _$FocusDataImpl.fromJson;

  @override
  bool get isFocusing;
  @override
  int get sinceLastChange;
  @override
  int get focusTimeLeft;
  @override
  int get numFocuses;
  @override
  int get lastNotificationTime; // Unix timestamp in seconds
  @override
  int get lastActivityTime; // Unix timestamp in seconds
  @override
  int get lastFocusEndTime;

  /// Create a copy of FocusData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FocusDataImplCopyWith<_$FocusDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
