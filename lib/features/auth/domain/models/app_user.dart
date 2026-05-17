import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    @Default('') String id,
    @Default('New User') String fullName,
    @Default('') String email,
    @Default('member') String role,
    String? assignedPond,
    String? fcmToken,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? lastTokenUpdate,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
