// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FocusState _$FocusStateFromJson(Map<String, dynamic> json) => _FocusState(
  focusData: json['focusData'] == null
      ? const FocusData()
      : FocusData.fromJson(json['focusData'] as Map<String, dynamic>),
  status:
      $enumDecodeNullable(_$FocusStatusEnumMap, json['status']) ??
      FocusStatus.loading,
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$FocusStateToJson(_FocusState instance) =>
    <String, dynamic>{
      'focusData': instance.focusData,
      'status': _$FocusStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
    };

const _$FocusStatusEnumMap = {
  FocusStatus.loading: 'loading',
  FocusStatus.ready: 'ready',
  FocusStatus.error: 'error',
};
