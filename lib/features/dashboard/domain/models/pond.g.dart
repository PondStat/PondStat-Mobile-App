// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pond.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Pond _$PondFromJson(Map<String, dynamic> json) => _Pond(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  species: json['species'] as String? ?? '',
  stockingQuantity: (json['stockingQuantity'] as num?)?.toInt() ?? 0,
  targetCulturePeriodDays:
      (json['targetCulturePeriodDays'] as num?)?.toInt() ?? 0,
  ownerId: json['ownerId'] as String? ?? '',
  memberIds:
      (json['memberIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  roles:
      (json['roles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const {},
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
);

Map<String, dynamic> _$PondToJson(_Pond instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'species': instance.species,
  'stockingQuantity': instance.stockingQuantity,
  'targetCulturePeriodDays': instance.targetCulturePeriodDays,
  'ownerId': instance.ownerId,
  'memberIds': instance.memberIds,
  'roles': instance.roles,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
};
