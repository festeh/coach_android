// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_selection_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSelectionStateImpl _$$AppSelectionStateImplFromJson(
  Map<String, dynamic> json,
) => _$AppSelectionStateImpl(
  selectedPackages:
      (json['selectedPackages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ??
      const {},
  isLoading: json['isLoading'] as bool? ?? false,
  errorMessage: json['errorMessage'] as String?,
);

Map<String, dynamic> _$$AppSelectionStateImplToJson(
  _$AppSelectionStateImpl instance,
) => <String, dynamic>{
  'selectedPackages': instance.selectedPackages.toList(),
  'isLoading': instance.isLoading,
  'errorMessage': instance.errorMessage,
};
