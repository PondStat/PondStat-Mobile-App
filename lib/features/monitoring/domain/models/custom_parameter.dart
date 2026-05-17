import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'custom_parameter.freezed.dart';
part 'custom_parameter.g.dart';

@freezed
abstract class CustomParameter with _$CustomParameter {
  const factory CustomParameter({
    @Default('') String id,
    required String label,
    required String unit,
    required String type,
    required String category,
    @TimestampConverter() DateTime? createdAt,
    @Default('') String createdBy,
  }) = _CustomParameter;

  factory CustomParameter.fromJson(Map<String, dynamic> json) =>
      _$CustomParameterFromJson(json);
}
