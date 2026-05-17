import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'measurement.freezed.dart';
part 'measurement.g.dart';

@freezed
abstract class Measurement with _$Measurement {
  const factory Measurement({
    @Default('') String id,
    required String pondId,
    @Default('') String dateKey,
    @TimestampConverter() DateTime? timestamp,
    @TimestampConverter() DateTime? recordedAt,
    @Default('') String recordedBy,
    @Default('Unknown') String recorderName,
    required String type,
    required String parameter,
    required double value,
    required String unit,
    @Default('') String timeString,
    @Default({}) Map<String, double> pointValues,
    @Default({}) Map<String, List<double>> replicateValues,
    String? notes,
    Map<String, dynamic>? alert,
    // Edit metadata
    @TimestampConverter() DateTime? editedAt,
    String? editedBy,
    String? editorName,
  }) = _Measurement;

  factory Measurement.fromJson(Map<String, dynamic> json) =>
      _$MeasurementFromJson(json);
}
