// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_selection_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSelectionState _$AppSelectionStateFromJson(Map<String, dynamic> json) =>
    _AppSelectionState(
      selectedPackages:
          (json['selectedPackages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const {},
    );

Map<String, dynamic> _$AppSelectionStateToJson(_AppSelectionState instance) =>
    <String, dynamic>{'selectedPackages': instance.selectedPackages.toList()};
