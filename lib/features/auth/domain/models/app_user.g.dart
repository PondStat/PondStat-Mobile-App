// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String? ?? '',
  fullName: json['fullName'] as String? ?? 'New User',
  email: json['email'] as String? ?? '',
  role: json['role'] as String? ?? 'member',
  assignedPond: json['assignedPond'] as String?,
  fcmToken: json['fcmToken'] as String?,
  createdAt: const TimestampConverter().fromJson(json['createdAt']),
  lastTokenUpdate: const TimestampConverter().fromJson(json['lastTokenUpdate']),
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'fullName': instance.fullName,
  'email': instance.email,
  'role': instance.role,
  'assignedPond': instance.assignedPond,
  'fcmToken': instance.fcmToken,
  'createdAt': const TimestampConverter().toJson(instance.createdAt),
  'lastTokenUpdate': const TimestampConverter().toJson(
    instance.lastTokenUpdate,
  ),
};
