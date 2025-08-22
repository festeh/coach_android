// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monitoring_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MonitoringState _$MonitoringStateFromJson(Map<String, dynamic> json) {
  return _MonitoringState.fromJson(json);
}

/// @nodoc
mixin _$MonitoringState {
  bool get isMonitoring => throw _privateConstructorUsedError;
  bool get hasUsageStatsPermission => throw _privateConstructorUsedError;
  bool get hasOverlayPermission => throw _privateConstructorUsedError;
  String? get currentForegroundApp => throw _privateConstructorUsedError;
  DateTime? get lastChecked => throw _privateConstructorUsedError;

  /// Serializes this MonitoringState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MonitoringState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MonitoringStateCopyWith<MonitoringState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MonitoringStateCopyWith<$Res> {
  factory $MonitoringStateCopyWith(
    MonitoringState value,
    $Res Function(MonitoringState) then,
  ) = _$MonitoringStateCopyWithImpl<$Res, MonitoringState>;
  @useResult
  $Res call({
    bool isMonitoring,
    bool hasUsageStatsPermission,
    bool hasOverlayPermission,
    String? currentForegroundApp,
    DateTime? lastChecked,
  });
}

/// @nodoc
class _$MonitoringStateCopyWithImpl<$Res, $Val extends MonitoringState>
    implements $MonitoringStateCopyWith<$Res> {
  _$MonitoringStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MonitoringState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isMonitoring = null,
    Object? hasUsageStatsPermission = null,
    Object? hasOverlayPermission = null,
    Object? currentForegroundApp = freezed,
    Object? lastChecked = freezed,
  }) {
    return _then(
      _value.copyWith(
            isMonitoring: null == isMonitoring
                ? _value.isMonitoring
                : isMonitoring // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasUsageStatsPermission: null == hasUsageStatsPermission
                ? _value.hasUsageStatsPermission
                : hasUsageStatsPermission // ignore: cast_nullable_to_non_nullable
                      as bool,
            hasOverlayPermission: null == hasOverlayPermission
                ? _value.hasOverlayPermission
                : hasOverlayPermission // ignore: cast_nullable_to_non_nullable
                      as bool,
            currentForegroundApp: freezed == currentForegroundApp
                ? _value.currentForegroundApp
                : currentForegroundApp // ignore: cast_nullable_to_non_nullable
                      as String?,
            lastChecked: freezed == lastChecked
                ? _value.lastChecked
                : lastChecked // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MonitoringStateImplCopyWith<$Res>
    implements $MonitoringStateCopyWith<$Res> {
  factory _$$MonitoringStateImplCopyWith(
    _$MonitoringStateImpl value,
    $Res Function(_$MonitoringStateImpl) then,
  ) = __$$MonitoringStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    bool isMonitoring,
    bool hasUsageStatsPermission,
    bool hasOverlayPermission,
    String? currentForegroundApp,
    DateTime? lastChecked,
  });
}

/// @nodoc
class __$$MonitoringStateImplCopyWithImpl<$Res>
    extends _$MonitoringStateCopyWithImpl<$Res, _$MonitoringStateImpl>
    implements _$$MonitoringStateImplCopyWith<$Res> {
  __$$MonitoringStateImplCopyWithImpl(
    _$MonitoringStateImpl _value,
    $Res Function(_$MonitoringStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MonitoringState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isMonitoring = null,
    Object? hasUsageStatsPermission = null,
    Object? hasOverlayPermission = null,
    Object? currentForegroundApp = freezed,
    Object? lastChecked = freezed,
  }) {
    return _then(
      _$MonitoringStateImpl(
        isMonitoring: null == isMonitoring
            ? _value.isMonitoring
            : isMonitoring // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasUsageStatsPermission: null == hasUsageStatsPermission
            ? _value.hasUsageStatsPermission
            : hasUsageStatsPermission // ignore: cast_nullable_to_non_nullable
                  as bool,
        hasOverlayPermission: null == hasOverlayPermission
            ? _value.hasOverlayPermission
            : hasOverlayPermission // ignore: cast_nullable_to_non_nullable
                  as bool,
        currentForegroundApp: freezed == currentForegroundApp
            ? _value.currentForegroundApp
            : currentForegroundApp // ignore: cast_nullable_to_non_nullable
                  as String?,
        lastChecked: freezed == lastChecked
            ? _value.lastChecked
            : lastChecked // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MonitoringStateImpl implements _MonitoringState {
  const _$MonitoringStateImpl({
    this.isMonitoring = false,
    this.hasUsageStatsPermission = false,
    this.hasOverlayPermission = false,
    this.currentForegroundApp,
    this.lastChecked,
  });

  factory _$MonitoringStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$MonitoringStateImplFromJson(json);

  @override
  @JsonKey()
  final bool isMonitoring;
  @override
  @JsonKey()
  final bool hasUsageStatsPermission;
  @override
  @JsonKey()
  final bool hasOverlayPermission;
  @override
  final String? currentForegroundApp;
  @override
  final DateTime? lastChecked;

  @override
  String toString() {
    return 'MonitoringState(isMonitoring: $isMonitoring, hasUsageStatsPermission: $hasUsageStatsPermission, hasOverlayPermission: $hasOverlayPermission, currentForegroundApp: $currentForegroundApp, lastChecked: $lastChecked)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MonitoringStateImpl &&
            (identical(other.isMonitoring, isMonitoring) ||
                other.isMonitoring == isMonitoring) &&
            (identical(
                  other.hasUsageStatsPermission,
                  hasUsageStatsPermission,
                ) ||
                other.hasUsageStatsPermission == hasUsageStatsPermission) &&
            (identical(other.hasOverlayPermission, hasOverlayPermission) ||
                other.hasOverlayPermission == hasOverlayPermission) &&
            (identical(other.currentForegroundApp, currentForegroundApp) ||
                other.currentForegroundApp == currentForegroundApp) &&
            (identical(other.lastChecked, lastChecked) ||
                other.lastChecked == lastChecked));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    isMonitoring,
    hasUsageStatsPermission,
    hasOverlayPermission,
    currentForegroundApp,
    lastChecked,
  );

  /// Create a copy of MonitoringState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MonitoringStateImplCopyWith<_$MonitoringStateImpl> get copyWith =>
      __$$MonitoringStateImplCopyWithImpl<_$MonitoringStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MonitoringStateImplToJson(this);
  }
}

abstract class _MonitoringState implements MonitoringState {
  const factory _MonitoringState({
    final bool isMonitoring,
    final bool hasUsageStatsPermission,
    final bool hasOverlayPermission,
    final String? currentForegroundApp,
    final DateTime? lastChecked,
  }) = _$MonitoringStateImpl;

  factory _MonitoringState.fromJson(Map<String, dynamic> json) =
      _$MonitoringStateImpl.fromJson;

  @override
  bool get isMonitoring;
  @override
  bool get hasUsageStatsPermission;
  @override
  bool get hasOverlayPermission;
  @override
  String? get currentForegroundApp;
  @override
  DateTime? get lastChecked;

  /// Create a copy of MonitoringState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MonitoringStateImplCopyWith<_$MonitoringStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
