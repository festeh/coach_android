// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FocusDataImpl _$$FocusDataImplFromJson(Map<String, dynamic> json) =>
    _$FocusDataImpl(
      isFocusing: json['isFocusing'] as bool? ?? false,
      sinceLastChange: (json['sinceLastChange'] as num?)?.toInt() ?? 0,
      focusTimeLeft: (json['focusTimeLeft'] as num?)?.toInt() ?? 0,
      numFocuses: (json['numFocuses'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$FocusDataImplToJson(_$FocusDataImpl instance) =>
    <String, dynamic>{
      'isFocusing': instance.isFocusing,
      'sinceLastChange': instance.sinceLastChange,
      'focusTimeLeft': instance.focusTimeLeft,
      'numFocuses': instance.numFocuses,
    };
