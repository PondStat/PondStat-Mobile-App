// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pond_chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PondChatMessage _$PondChatMessageFromJson(Map<String, dynamic> json) =>
    _PondChatMessage(
      id: json['id'] as String,
      pondId: json['pondId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderPhotoUrl: json['senderPhotoUrl'] as String?,
      message: json['message'] as String,
      imageUrl: json['imageUrl'] as String?,
      taggedParameter: json['taggedParameter'] as String?,
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$PondChatMessageToJson(_PondChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pondId': instance.pondId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderPhotoUrl': instance.senderPhotoUrl,
      'message': instance.message,
      'imageUrl': instance.imageUrl,
      'taggedParameter': instance.taggedParameter,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };
