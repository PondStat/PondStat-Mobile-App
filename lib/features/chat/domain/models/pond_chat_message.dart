import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'pond_chat_message.freezed.dart';
part 'pond_chat_message.g.dart';

@freezed
abstract class PondChatMessage with _$PondChatMessage {
  const factory PondChatMessage({
    required String id,
    required String pondId,
    required String senderId,
    required String senderName,
    String? senderPhotoUrl,
    required String message,
    String? imageUrl,
    String? taggedParameter,
    @TimestampConverter() DateTime? createdAt,
  }) = _PondChatMessage;

  factory PondChatMessage.fromJson(Map<String, dynamic> json) =>
      _$PondChatMessageFromJson(json);
}
