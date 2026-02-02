// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_selection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AppSelectionState {

 Set<String> get selectedPackages;
/// Create a copy of AppSelectionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppSelectionStateCopyWith<AppSelectionState> get copyWith => _$AppSelectionStateCopyWithImpl<AppSelectionState>(this as AppSelectionState, _$identity);

  /// Serializes this AppSelectionState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppSelectionState&&const DeepCollectionEquality().equals(other.selectedPackages, selectedPackages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectedPackages));

@override
String toString() {
  return 'AppSelectionState(selectedPackages: $selectedPackages)';
}


}

/// @nodoc
abstract mixin class $AppSelectionStateCopyWith<$Res>  {
  factory $AppSelectionStateCopyWith(AppSelectionState value, $Res Function(AppSelectionState) _then) = _$AppSelectionStateCopyWithImpl;
@useResult
$Res call({
 Set<String> selectedPackages
});




}
/// @nodoc
class _$AppSelectionStateCopyWithImpl<$Res>
    implements $AppSelectionStateCopyWith<$Res> {
  _$AppSelectionStateCopyWithImpl(this._self, this._then);

  final AppSelectionState _self;
  final $Res Function(AppSelectionState) _then;

/// Create a copy of AppSelectionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectedPackages = null,}) {
  return _then(_self.copyWith(
selectedPackages: null == selectedPackages ? _self.selectedPackages : selectedPackages // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [AppSelectionState].
extension AppSelectionStatePatterns on AppSelectionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppSelectionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppSelectionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppSelectionState value)  $default,){
final _that = this;
switch (_that) {
case _AppSelectionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppSelectionState value)?  $default,){
final _that = this;
switch (_that) {
case _AppSelectionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> selectedPackages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppSelectionState() when $default != null:
return $default(_that.selectedPackages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> selectedPackages)  $default,) {final _that = this;
switch (_that) {
case _AppSelectionState():
return $default(_that.selectedPackages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> selectedPackages)?  $default,) {final _that = this;
switch (_that) {
case _AppSelectionState() when $default != null:
return $default(_that.selectedPackages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AppSelectionState implements AppSelectionState {
  const _AppSelectionState({final  Set<String> selectedPackages = const {}}): _selectedPackages = selectedPackages;
  factory _AppSelectionState.fromJson(Map<String, dynamic> json) => _$AppSelectionStateFromJson(json);

 final  Set<String> _selectedPackages;
@override@JsonKey() Set<String> get selectedPackages {
  if (_selectedPackages is EqualUnmodifiableSetView) return _selectedPackages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedPackages);
}


/// Create a copy of AppSelectionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppSelectionStateCopyWith<_AppSelectionState> get copyWith => __$AppSelectionStateCopyWithImpl<_AppSelectionState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AppSelectionStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppSelectionState&&const DeepCollectionEquality().equals(other._selectedPackages, _selectedPackages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectedPackages));

@override
String toString() {
  return 'AppSelectionState(selectedPackages: $selectedPackages)';
}


}

/// @nodoc
abstract mixin class _$AppSelectionStateCopyWith<$Res> implements $AppSelectionStateCopyWith<$Res> {
  factory _$AppSelectionStateCopyWith(_AppSelectionState value, $Res Function(_AppSelectionState) _then) = __$AppSelectionStateCopyWithImpl;
@override @useResult
$Res call({
 Set<String> selectedPackages
});




}
/// @nodoc
class __$AppSelectionStateCopyWithImpl<$Res>
    implements _$AppSelectionStateCopyWith<$Res> {
  __$AppSelectionStateCopyWithImpl(this._self, this._then);

  final _AppSelectionState _self;
  final $Res Function(_AppSelectionState) _then;

/// Create a copy of AppSelectionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectedPackages = null,}) {
  return _then(_AppSelectionState(
selectedPackages: null == selectedPackages ? _self._selectedPackages : selectedPackages // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
