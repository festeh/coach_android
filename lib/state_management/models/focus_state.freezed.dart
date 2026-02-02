// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FocusState {

 FocusData get focusData; FocusStatus get status; String? get errorMessage;
/// Create a copy of FocusState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusStateCopyWith<FocusState> get copyWith => _$FocusStateCopyWithImpl<FocusState>(this as FocusState, _$identity);

  /// Serializes this FocusState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusState&&(identical(other.focusData, focusData) || other.focusData == focusData)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,focusData,status,errorMessage);

@override
String toString() {
  return 'FocusState(focusData: $focusData, status: $status, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $FocusStateCopyWith<$Res>  {
  factory $FocusStateCopyWith(FocusState value, $Res Function(FocusState) _then) = _$FocusStateCopyWithImpl;
@useResult
$Res call({
 FocusData focusData, FocusStatus status, String? errorMessage
});


$FocusDataCopyWith<$Res> get focusData;

}
/// @nodoc
class _$FocusStateCopyWithImpl<$Res>
    implements $FocusStateCopyWith<$Res> {
  _$FocusStateCopyWithImpl(this._self, this._then);

  final FocusState _self;
  final $Res Function(FocusState) _then;

/// Create a copy of FocusState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? focusData = null,Object? status = null,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
focusData: null == focusData ? _self.focusData : focusData // ignore: cast_nullable_to_non_nullable
as FocusData,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FocusStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of FocusState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FocusDataCopyWith<$Res> get focusData {
  
  return $FocusDataCopyWith<$Res>(_self.focusData, (value) {
    return _then(_self.copyWith(focusData: value));
  });
}
}


/// Adds pattern-matching-related methods to [FocusState].
extension FocusStatePatterns on FocusState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FocusState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FocusState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FocusState value)  $default,){
final _that = this;
switch (_that) {
case _FocusState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FocusState value)?  $default,){
final _that = this;
switch (_that) {
case _FocusState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FocusData focusData,  FocusStatus status,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FocusState() when $default != null:
return $default(_that.focusData,_that.status,_that.errorMessage);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FocusData focusData,  FocusStatus status,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _FocusState():
return $default(_that.focusData,_that.status,_that.errorMessage);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FocusData focusData,  FocusStatus status,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _FocusState() when $default != null:
return $default(_that.focusData,_that.status,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FocusState implements FocusState {
  const _FocusState({this.focusData = const FocusData(), this.status = FocusStatus.loading, this.errorMessage});
  factory _FocusState.fromJson(Map<String, dynamic> json) => _$FocusStateFromJson(json);

@override@JsonKey() final  FocusData focusData;
@override@JsonKey() final  FocusStatus status;
@override final  String? errorMessage;

/// Create a copy of FocusState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FocusStateCopyWith<_FocusState> get copyWith => __$FocusStateCopyWithImpl<_FocusState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FocusStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FocusState&&(identical(other.focusData, focusData) || other.focusData == focusData)&&(identical(other.status, status) || other.status == status)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,focusData,status,errorMessage);

@override
String toString() {
  return 'FocusState(focusData: $focusData, status: $status, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$FocusStateCopyWith<$Res> implements $FocusStateCopyWith<$Res> {
  factory _$FocusStateCopyWith(_FocusState value, $Res Function(_FocusState) _then) = __$FocusStateCopyWithImpl;
@override @useResult
$Res call({
 FocusData focusData, FocusStatus status, String? errorMessage
});


@override $FocusDataCopyWith<$Res> get focusData;

}
/// @nodoc
class __$FocusStateCopyWithImpl<$Res>
    implements _$FocusStateCopyWith<$Res> {
  __$FocusStateCopyWithImpl(this._self, this._then);

  final _FocusState _self;
  final $Res Function(_FocusState) _then;

/// Create a copy of FocusState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? focusData = null,Object? status = null,Object? errorMessage = freezed,}) {
  return _then(_FocusState(
focusData: null == focusData ? _self.focusData : focusData // ignore: cast_nullable_to_non_nullable
as FocusData,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FocusStatus,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of FocusState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FocusDataCopyWith<$Res> get focusData {
  
  return $FocusDataCopyWith<$Res>(_self.focusData, (value) {
    return _then(_self.copyWith(focusData: value));
  });
}
}

// dart format on
