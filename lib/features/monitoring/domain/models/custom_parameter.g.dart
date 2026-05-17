// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_parameter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomParameter _$CustomParameterFromJson(Map<String, dynamic> json) =>
    _CustomParameter(
      id: json['id'] as String? ?? '',
      label: json['label'] as String,
      unit: json['unit'] as String,
      type: json['type'] as String,
      category: json['category'] as String,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
      createdBy: json['createdBy'] as String? ?? '',
    );

Map<String, dynamic> _$CustomParameterToJson(_CustomParameter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'unit': instance.unit,
      'type': instance.type,
      'category': instance.category,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'createdBy': instance.createdBy,
    };
