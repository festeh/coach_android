// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'log_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LogEntry {

 DateTime get timestamp; LogLevel get level; LogSource get source; LogCategory get category; String get message; Map<String, dynamic>? get metadata; String? get stackTrace;
/// Create a copy of LogEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogEntryCopyWith<LogEntry> get copyWith => _$LogEntryCopyWithImpl<LogEntry>(this as LogEntry, _$identity);

  /// Serializes this LogEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogEntry&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.level, level) || other.level == level)&&(identical(other.source, source) || other.source == source)&&(identical(other.category, category) || other.category == category)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.metadata, metadata)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,level,source,category,message,const DeepCollectionEquality().hash(metadata),stackTrace);

@override
String toString() {
  return 'LogEntry(timestamp: $timestamp, level: $level, source: $source, category: $category, message: $message, metadata: $metadata, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class $LogEntryCopyWith<$Res>  {
  factory $LogEntryCopyWith(LogEntry value, $Res Function(LogEntry) _then) = _$LogEntryCopyWithImpl;
@useResult
$Res call({
 DateTime timestamp, LogLevel level, LogSource source, LogCategory category, String message, Map<String, dynamic>? metadata, String? stackTrace
});




}
/// @nodoc
class _$LogEntryCopyWithImpl<$Res>
    implements $LogEntryCopyWith<$Res> {
  _$LogEntryCopyWithImpl(this._self, this._then);

  final LogEntry _self;
  final $Res Function(LogEntry) _then;

/// Create a copy of LogEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? timestamp = null,Object? level = null,Object? source = null,Object? category = null,Object? message = null,Object? metadata = freezed,Object? stackTrace = freezed,}) {
  return _then(_self.copyWith(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LogSource,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as LogCategory,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,metadata: freezed == metadata ? _self.metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [LogEntry].
extension LogEntryPatterns on LogEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LogEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LogEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LogEntry value)  $default,){
final _that = this;
switch (_that) {
case _LogEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LogEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LogEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime timestamp,  LogLevel level,  LogSource source,  LogCategory category,  String message,  Map<String, dynamic>? metadata,  String? stackTrace)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LogEntry() when $default != null:
return $default(_that.timestamp,_that.level,_that.source,_that.category,_that.message,_that.metadata,_that.stackTrace);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime timestamp,  LogLevel level,  LogSource source,  LogCategory category,  String message,  Map<String, dynamic>? metadata,  String? stackTrace)  $default,) {final _that = this;
switch (_that) {
case _LogEntry():
return $default(_that.timestamp,_that.level,_that.source,_that.category,_that.message,_that.metadata,_that.stackTrace);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime timestamp,  LogLevel level,  LogSource source,  LogCategory category,  String message,  Map<String, dynamic>? metadata,  String? stackTrace)?  $default,) {final _that = this;
switch (_that) {
case _LogEntry() when $default != null:
return $default(_that.timestamp,_that.level,_that.source,_that.category,_that.message,_that.metadata,_that.stackTrace);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LogEntry implements LogEntry {
  const _LogEntry({required this.timestamp, required this.level, required this.source, required this.category, required this.message, final  Map<String, dynamic>? metadata, this.stackTrace}): _metadata = metadata;
  factory _LogEntry.fromJson(Map<String, dynamic> json) => _$LogEntryFromJson(json);

@override final  DateTime timestamp;
@override final  LogLevel level;
@override final  LogSource source;
@override final  LogCategory category;
@override final  String message;
 final  Map<String, dynamic>? _metadata;
@override Map<String, dynamic>? get metadata {
  final value = _metadata;
  if (value == null) return null;
  if (_metadata is EqualUnmodifiableMapView) return _metadata;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override final  String? stackTrace;

/// Create a copy of LogEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LogEntryCopyWith<_LogEntry> get copyWith => __$LogEntryCopyWithImpl<_LogEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LogEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LogEntry&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.level, level) || other.level == level)&&(identical(other.source, source) || other.source == source)&&(identical(other.category, category) || other.category == category)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other._metadata, _metadata)&&(identical(other.stackTrace, stackTrace) || other.stackTrace == stackTrace));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,timestamp,level,source,category,message,const DeepCollectionEquality().hash(_metadata),stackTrace);

@override
String toString() {
  return 'LogEntry(timestamp: $timestamp, level: $level, source: $source, category: $category, message: $message, metadata: $metadata, stackTrace: $stackTrace)';
}


}

/// @nodoc
abstract mixin class _$LogEntryCopyWith<$Res> implements $LogEntryCopyWith<$Res> {
  factory _$LogEntryCopyWith(_LogEntry value, $Res Function(_LogEntry) _then) = __$LogEntryCopyWithImpl;
@override @useResult
$Res call({
 DateTime timestamp, LogLevel level, LogSource source, LogCategory category, String message, Map<String, dynamic>? metadata, String? stackTrace
});




}
/// @nodoc
class __$LogEntryCopyWithImpl<$Res>
    implements _$LogEntryCopyWith<$Res> {
  __$LogEntryCopyWithImpl(this._self, this._then);

  final _LogEntry _self;
  final $Res Function(_LogEntry) _then;

/// Create a copy of LogEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? timestamp = null,Object? level = null,Object? source = null,Object? category = null,Object? message = null,Object? metadata = freezed,Object? stackTrace = freezed,}) {
  return _then(_LogEntry(
timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as LogLevel,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as LogSource,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as LogCategory,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,metadata: freezed == metadata ? _self._metadata : metadata // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,stackTrace: freezed == stackTrace ? _self.stackTrace : stackTrace // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
