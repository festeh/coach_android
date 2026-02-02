// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'focus_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FocusData {

 bool get isFocusing; int get sinceLastChange; int get focusTimeLeft; int get numFocuses; int get lastNotificationTime;// Unix timestamp in seconds
 int get lastActivityTime;// Unix timestamp in seconds
 int get lastFocusEndTime;
/// Create a copy of FocusData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FocusDataCopyWith<FocusData> get copyWith => _$FocusDataCopyWithImpl<FocusData>(this as FocusData, _$identity);

  /// Serializes this FocusData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FocusData&&(identical(other.isFocusing, isFocusing) || other.isFocusing == isFocusing)&&(identical(other.sinceLastChange, sinceLastChange) || other.sinceLastChange == sinceLastChange)&&(identical(other.focusTimeLeft, focusTimeLeft) || other.focusTimeLeft == focusTimeLeft)&&(identical(other.numFocuses, numFocuses) || other.numFocuses == numFocuses)&&(identical(other.lastNotificationTime, lastNotificationTime) || other.lastNotificationTime == lastNotificationTime)&&(identical(other.lastActivityTime, lastActivityTime) || other.lastActivityTime == lastActivityTime)&&(identical(other.lastFocusEndTime, lastFocusEndTime) || other.lastFocusEndTime == lastFocusEndTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFocusing,sinceLastChange,focusTimeLeft,numFocuses,lastNotificationTime,lastActivityTime,lastFocusEndTime);

@override
String toString() {
  return 'FocusData(isFocusing: $isFocusing, sinceLastChange: $sinceLastChange, focusTimeLeft: $focusTimeLeft, numFocuses: $numFocuses, lastNotificationTime: $lastNotificationTime, lastActivityTime: $lastActivityTime, lastFocusEndTime: $lastFocusEndTime)';
}


}

/// @nodoc
abstract mixin class $FocusDataCopyWith<$Res>  {
  factory $FocusDataCopyWith(FocusData value, $Res Function(FocusData) _then) = _$FocusDataCopyWithImpl;
@useResult
$Res call({
 bool isFocusing, int sinceLastChange, int focusTimeLeft, int numFocuses, int lastNotificationTime, int lastActivityTime, int lastFocusEndTime
});




}
/// @nodoc
class _$FocusDataCopyWithImpl<$Res>
    implements $FocusDataCopyWith<$Res> {
  _$FocusDataCopyWithImpl(this._self, this._then);

  final FocusData _self;
  final $Res Function(FocusData) _then;

/// Create a copy of FocusData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isFocusing = null,Object? sinceLastChange = null,Object? focusTimeLeft = null,Object? numFocuses = null,Object? lastNotificationTime = null,Object? lastActivityTime = null,Object? lastFocusEndTime = null,}) {
  return _then(_self.copyWith(
isFocusing: null == isFocusing ? _self.isFocusing : isFocusing // ignore: cast_nullable_to_non_nullable
as bool,sinceLastChange: null == sinceLastChange ? _self.sinceLastChange : sinceLastChange // ignore: cast_nullable_to_non_nullable
as int,focusTimeLeft: null == focusTimeLeft ? _self.focusTimeLeft : focusTimeLeft // ignore: cast_nullable_to_non_nullable
as int,numFocuses: null == numFocuses ? _self.numFocuses : numFocuses // ignore: cast_nullable_to_non_nullable
as int,lastNotificationTime: null == lastNotificationTime ? _self.lastNotificationTime : lastNotificationTime // ignore: cast_nullable_to_non_nullable
as int,lastActivityTime: null == lastActivityTime ? _self.lastActivityTime : lastActivityTime // ignore: cast_nullable_to_non_nullable
as int,lastFocusEndTime: null == lastFocusEndTime ? _self.lastFocusEndTime : lastFocusEndTime // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FocusData].
extension FocusDataPatterns on FocusData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FocusData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FocusData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FocusData value)  $default,){
final _that = this;
switch (_that) {
case _FocusData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FocusData value)?  $default,){
final _that = this;
switch (_that) {
case _FocusData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isFocusing,  int sinceLastChange,  int focusTimeLeft,  int numFocuses,  int lastNotificationTime,  int lastActivityTime,  int lastFocusEndTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FocusData() when $default != null:
return $default(_that.isFocusing,_that.sinceLastChange,_that.focusTimeLeft,_that.numFocuses,_that.lastNotificationTime,_that.lastActivityTime,_that.lastFocusEndTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isFocusing,  int sinceLastChange,  int focusTimeLeft,  int numFocuses,  int lastNotificationTime,  int lastActivityTime,  int lastFocusEndTime)  $default,) {final _that = this;
switch (_that) {
case _FocusData():
return $default(_that.isFocusing,_that.sinceLastChange,_that.focusTimeLeft,_that.numFocuses,_that.lastNotificationTime,_that.lastActivityTime,_that.lastFocusEndTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isFocusing,  int sinceLastChange,  int focusTimeLeft,  int numFocuses,  int lastNotificationTime,  int lastActivityTime,  int lastFocusEndTime)?  $default,) {final _that = this;
switch (_that) {
case _FocusData() when $default != null:
return $default(_that.isFocusing,_that.sinceLastChange,_that.focusTimeLeft,_that.numFocuses,_that.lastNotificationTime,_that.lastActivityTime,_that.lastFocusEndTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FocusData implements FocusData {
  const _FocusData({this.isFocusing = false, this.sinceLastChange = 0, this.focusTimeLeft = 0, this.numFocuses = 0, this.lastNotificationTime = 0, this.lastActivityTime = 0, this.lastFocusEndTime = 0});
  factory _FocusData.fromJson(Map<String, dynamic> json) => _$FocusDataFromJson(json);

@override@JsonKey() final  bool isFocusing;
@override@JsonKey() final  int sinceLastChange;
@override@JsonKey() final  int focusTimeLeft;
@override@JsonKey() final  int numFocuses;
@override@JsonKey() final  int lastNotificationTime;
// Unix timestamp in seconds
@override@JsonKey() final  int lastActivityTime;
// Unix timestamp in seconds
@override@JsonKey() final  int lastFocusEndTime;

/// Create a copy of FocusData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FocusDataCopyWith<_FocusData> get copyWith => __$FocusDataCopyWithImpl<_FocusData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FocusDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FocusData&&(identical(other.isFocusing, isFocusing) || other.isFocusing == isFocusing)&&(identical(other.sinceLastChange, sinceLastChange) || other.sinceLastChange == sinceLastChange)&&(identical(other.focusTimeLeft, focusTimeLeft) || other.focusTimeLeft == focusTimeLeft)&&(identical(other.numFocuses, numFocuses) || other.numFocuses == numFocuses)&&(identical(other.lastNotificationTime, lastNotificationTime) || other.lastNotificationTime == lastNotificationTime)&&(identical(other.lastActivityTime, lastActivityTime) || other.lastActivityTime == lastActivityTime)&&(identical(other.lastFocusEndTime, lastFocusEndTime) || other.lastFocusEndTime == lastFocusEndTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isFocusing,sinceLastChange,focusTimeLeft,numFocuses,lastNotificationTime,lastActivityTime,lastFocusEndTime);

@override
String toString() {
  return 'FocusData(isFocusing: $isFocusing, sinceLastChange: $sinceLastChange, focusTimeLeft: $focusTimeLeft, numFocuses: $numFocuses, lastNotificationTime: $lastNotificationTime, lastActivityTime: $lastActivityTime, lastFocusEndTime: $lastFocusEndTime)';
}


}

/// @nodoc
abstract mixin class _$FocusDataCopyWith<$Res> implements $FocusDataCopyWith<$Res> {
  factory _$FocusDataCopyWith(_FocusData value, $Res Function(_FocusData) _then) = __$FocusDataCopyWithImpl;
@override @useResult
$Res call({
 bool isFocusing, int sinceLastChange, int focusTimeLeft, int numFocuses, int lastNotificationTime, int lastActivityTime, int lastFocusEndTime
});




}
/// @nodoc
class __$FocusDataCopyWithImpl<$Res>
    implements _$FocusDataCopyWith<$Res> {
  __$FocusDataCopyWithImpl(this._self, this._then);

  final _FocusData _self;
  final $Res Function(_FocusData) _then;

/// Create a copy of FocusData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isFocusing = null,Object? sinceLastChange = null,Object? focusTimeLeft = null,Object? numFocuses = null,Object? lastNotificationTime = null,Object? lastActivityTime = null,Object? lastFocusEndTime = null,}) {
  return _then(_FocusData(
isFocusing: null == isFocusing ? _self.isFocusing : isFocusing // ignore: cast_nullable_to_non_nullable
as bool,sinceLastChange: null == sinceLastChange ? _self.sinceLastChange : sinceLastChange // ignore: cast_nullable_to_non_nullable
as int,focusTimeLeft: null == focusTimeLeft ? _self.focusTimeLeft : focusTimeLeft // ignore: cast_nullable_to_non_nullable
as int,numFocuses: null == numFocuses ? _self.numFocuses : numFocuses // ignore: cast_nullable_to_non_nullable
as int,lastNotificationTime: null == lastNotificationTime ? _self.lastNotificationTime : lastNotificationTime // ignore: cast_nullable_to_non_nullable
as int,lastActivityTime: null == lastActivityTime ? _self.lastActivityTime : lastActivityTime // ignore: cast_nullable_to_non_nullable
as int,lastFocusEndTime: null == lastFocusEndTime ? _self.lastFocusEndTime : lastFocusEndTime // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
