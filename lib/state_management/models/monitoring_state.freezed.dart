// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monitoring_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MonitoringState {

 bool get isMonitoring; bool get hasUsageStatsPermission; bool get hasOverlayPermission; String? get currentForegroundApp; DateTime? get lastChecked;
/// Create a copy of MonitoringState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonitoringStateCopyWith<MonitoringState> get copyWith => _$MonitoringStateCopyWithImpl<MonitoringState>(this as MonitoringState, _$identity);

  /// Serializes this MonitoringState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonitoringState&&(identical(other.isMonitoring, isMonitoring) || other.isMonitoring == isMonitoring)&&(identical(other.hasUsageStatsPermission, hasUsageStatsPermission) || other.hasUsageStatsPermission == hasUsageStatsPermission)&&(identical(other.hasOverlayPermission, hasOverlayPermission) || other.hasOverlayPermission == hasOverlayPermission)&&(identical(other.currentForegroundApp, currentForegroundApp) || other.currentForegroundApp == currentForegroundApp)&&(identical(other.lastChecked, lastChecked) || other.lastChecked == lastChecked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isMonitoring,hasUsageStatsPermission,hasOverlayPermission,currentForegroundApp,lastChecked);

@override
String toString() {
  return 'MonitoringState(isMonitoring: $isMonitoring, hasUsageStatsPermission: $hasUsageStatsPermission, hasOverlayPermission: $hasOverlayPermission, currentForegroundApp: $currentForegroundApp, lastChecked: $lastChecked)';
}


}

/// @nodoc
abstract mixin class $MonitoringStateCopyWith<$Res>  {
  factory $MonitoringStateCopyWith(MonitoringState value, $Res Function(MonitoringState) _then) = _$MonitoringStateCopyWithImpl;
@useResult
$Res call({
 bool isMonitoring, bool hasUsageStatsPermission, bool hasOverlayPermission, String? currentForegroundApp, DateTime? lastChecked
});




}
/// @nodoc
class _$MonitoringStateCopyWithImpl<$Res>
    implements $MonitoringStateCopyWith<$Res> {
  _$MonitoringStateCopyWithImpl(this._self, this._then);

  final MonitoringState _self;
  final $Res Function(MonitoringState) _then;

/// Create a copy of MonitoringState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isMonitoring = null,Object? hasUsageStatsPermission = null,Object? hasOverlayPermission = null,Object? currentForegroundApp = freezed,Object? lastChecked = freezed,}) {
  return _then(_self.copyWith(
isMonitoring: null == isMonitoring ? _self.isMonitoring : isMonitoring // ignore: cast_nullable_to_non_nullable
as bool,hasUsageStatsPermission: null == hasUsageStatsPermission ? _self.hasUsageStatsPermission : hasUsageStatsPermission // ignore: cast_nullable_to_non_nullable
as bool,hasOverlayPermission: null == hasOverlayPermission ? _self.hasOverlayPermission : hasOverlayPermission // ignore: cast_nullable_to_non_nullable
as bool,currentForegroundApp: freezed == currentForegroundApp ? _self.currentForegroundApp : currentForegroundApp // ignore: cast_nullable_to_non_nullable
as String?,lastChecked: freezed == lastChecked ? _self.lastChecked : lastChecked // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MonitoringState].
extension MonitoringStatePatterns on MonitoringState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonitoringState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonitoringState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonitoringState value)  $default,){
final _that = this;
switch (_that) {
case _MonitoringState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonitoringState value)?  $default,){
final _that = this;
switch (_that) {
case _MonitoringState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isMonitoring,  bool hasUsageStatsPermission,  bool hasOverlayPermission,  String? currentForegroundApp,  DateTime? lastChecked)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonitoringState() when $default != null:
return $default(_that.isMonitoring,_that.hasUsageStatsPermission,_that.hasOverlayPermission,_that.currentForegroundApp,_that.lastChecked);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isMonitoring,  bool hasUsageStatsPermission,  bool hasOverlayPermission,  String? currentForegroundApp,  DateTime? lastChecked)  $default,) {final _that = this;
switch (_that) {
case _MonitoringState():
return $default(_that.isMonitoring,_that.hasUsageStatsPermission,_that.hasOverlayPermission,_that.currentForegroundApp,_that.lastChecked);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isMonitoring,  bool hasUsageStatsPermission,  bool hasOverlayPermission,  String? currentForegroundApp,  DateTime? lastChecked)?  $default,) {final _that = this;
switch (_that) {
case _MonitoringState() when $default != null:
return $default(_that.isMonitoring,_that.hasUsageStatsPermission,_that.hasOverlayPermission,_that.currentForegroundApp,_that.lastChecked);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MonitoringState implements MonitoringState {
  const _MonitoringState({this.isMonitoring = false, this.hasUsageStatsPermission = false, this.hasOverlayPermission = false, this.currentForegroundApp, this.lastChecked});
  factory _MonitoringState.fromJson(Map<String, dynamic> json) => _$MonitoringStateFromJson(json);

@override@JsonKey() final  bool isMonitoring;
@override@JsonKey() final  bool hasUsageStatsPermission;
@override@JsonKey() final  bool hasOverlayPermission;
@override final  String? currentForegroundApp;
@override final  DateTime? lastChecked;

/// Create a copy of MonitoringState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonitoringStateCopyWith<_MonitoringState> get copyWith => __$MonitoringStateCopyWithImpl<_MonitoringState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MonitoringStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonitoringState&&(identical(other.isMonitoring, isMonitoring) || other.isMonitoring == isMonitoring)&&(identical(other.hasUsageStatsPermission, hasUsageStatsPermission) || other.hasUsageStatsPermission == hasUsageStatsPermission)&&(identical(other.hasOverlayPermission, hasOverlayPermission) || other.hasOverlayPermission == hasOverlayPermission)&&(identical(other.currentForegroundApp, currentForegroundApp) || other.currentForegroundApp == currentForegroundApp)&&(identical(other.lastChecked, lastChecked) || other.lastChecked == lastChecked));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isMonitoring,hasUsageStatsPermission,hasOverlayPermission,currentForegroundApp,lastChecked);

@override
String toString() {
  return 'MonitoringState(isMonitoring: $isMonitoring, hasUsageStatsPermission: $hasUsageStatsPermission, hasOverlayPermission: $hasOverlayPermission, currentForegroundApp: $currentForegroundApp, lastChecked: $lastChecked)';
}


}

/// @nodoc
abstract mixin class _$MonitoringStateCopyWith<$Res> implements $MonitoringStateCopyWith<$Res> {
  factory _$MonitoringStateCopyWith(_MonitoringState value, $Res Function(_MonitoringState) _then) = __$MonitoringStateCopyWithImpl;
@override @useResult
$Res call({
 bool isMonitoring, bool hasUsageStatsPermission, bool hasOverlayPermission, String? currentForegroundApp, DateTime? lastChecked
});




}
/// @nodoc
class __$MonitoringStateCopyWithImpl<$Res>
    implements _$MonitoringStateCopyWith<$Res> {
  __$MonitoringStateCopyWithImpl(this._self, this._then);

  final _MonitoringState _self;
  final $Res Function(_MonitoringState) _then;

/// Create a copy of MonitoringState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isMonitoring = null,Object? hasUsageStatsPermission = null,Object? hasOverlayPermission = null,Object? currentForegroundApp = freezed,Object? lastChecked = freezed,}) {
  return _then(_MonitoringState(
isMonitoring: null == isMonitoring ? _self.isMonitoring : isMonitoring // ignore: cast_nullable_to_non_nullable
as bool,hasUsageStatsPermission: null == hasUsageStatsPermission ? _self.hasUsageStatsPermission : hasUsageStatsPermission // ignore: cast_nullable_to_non_nullable
as bool,hasOverlayPermission: null == hasOverlayPermission ? _self.hasOverlayPermission : hasOverlayPermission // ignore: cast_nullable_to_non_nullable
as bool,currentForegroundApp: freezed == currentForegroundApp ? _self.currentForegroundApp : currentForegroundApp // ignore: cast_nullable_to_non_nullable
as String?,lastChecked: freezed == lastChecked ? _self.lastChecked : lastChecked // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
