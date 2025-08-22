// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FocusStateImpl _$$FocusStateImplFromJson(Map<String, dynamic> json) =>
    _$FocusStateImpl(
      isFocusing: json['isFocusing'] as bool? ?? false,
      numFocuses: (json['numFocuses'] as num?)?.toInt() ?? 0,
      focusTimeLeft: (json['focusTimeLeft'] as num?)?.toDouble() ?? 0.0,
      status:
          $enumDecodeNullable(_$FocusStatusEnumMap, json['status']) ??
          FocusStatus.loading,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$FocusStateImplToJson(_$FocusStateImpl instance) =>
    <String, dynamic>{
      'isFocusing': instance.isFocusing,
      'numFocuses': instance.numFocuses,
      'focusTimeLeft': instance.focusTimeLeft,
      'status': _$FocusStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
    };

const _$FocusStatusEnumMap = {
  FocusStatus.loading: 'loading',
  FocusStatus.ready: 'ready',
  FocusStatus.error: 'error',
};
