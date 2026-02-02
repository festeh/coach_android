// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'focus_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FocusData _$FocusDataFromJson(Map<String, dynamic> json) => _FocusData(
  isFocusing: json['isFocusing'] as bool? ?? false,
  sinceLastChange: (json['sinceLastChange'] as num?)?.toInt() ?? 0,
  focusTimeLeft: (json['focusTimeLeft'] as num?)?.toInt() ?? 0,
  numFocuses: (json['numFocuses'] as num?)?.toInt() ?? 0,
  lastNotificationTime: (json['lastNotificationTime'] as num?)?.toInt() ?? 0,
  lastActivityTime: (json['lastActivityTime'] as num?)?.toInt() ?? 0,
  lastFocusEndTime: (json['lastFocusEndTime'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FocusDataToJson(_FocusData instance) =>
    <String, dynamic>{
      'isFocusing': instance.isFocusing,
      'sinceLastChange': instance.sinceLastChange,
      'focusTimeLeft': instance.focusTimeLeft,
      'numFocuses': instance.numFocuses,
      'lastNotificationTime': instance.lastNotificationTime,
      'lastActivityTime': instance.lastActivityTime,
      'lastFocusEndTime': instance.lastFocusEndTime,
    };
