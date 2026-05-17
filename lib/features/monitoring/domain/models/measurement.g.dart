// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Measurement _$MeasurementFromJson(Map<String, dynamic> json) => _Measurement(
  id: json['id'] as String? ?? '',
  pondId: json['pondId'] as String,
  dateKey: json['dateKey'] as String? ?? '',
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
  recordedAt: const TimestampConverter().fromJson(json['recordedAt']),
  recordedBy: json['recordedBy'] as String? ?? '',
  recorderName: json['recorderName'] as String? ?? 'Unknown',
  type: json['type'] as String,
  parameter: json['parameter'] as String,
  value: (json['value'] as num).toDouble(),
  unit: json['unit'] as String,
  timeString: json['timeString'] as String? ?? '',
  pointValues:
      (json['pointValues'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ) ??
      const {},
  replicateValues:
      (json['replicateValues'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
        ),
      ) ??
      const {},
  notes: json['notes'] as String?,
  alert: json['alert'] as Map<String, dynamic>?,
  editedAt: const TimestampConverter().fromJson(json['editedAt']),
  editedBy: json['editedBy'] as String?,
  editorName: json['editorName'] as String?,
);

Map<String, dynamic> _$MeasurementToJson(_Measurement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pondId': instance.pondId,
      'dateKey': instance.dateKey,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'recordedAt': const TimestampConverter().toJson(instance.recordedAt),
      'recordedBy': instance.recordedBy,
      'recorderName': instance.recorderName,
      'type': instance.type,
      'parameter': instance.parameter,
      'value': instance.value,
      'unit': instance.unit,
      'timeString': instance.timeString,
      'pointValues': instance.pointValues,
      'replicateValues': instance.replicateValues,
      'notes': instance.notes,
      'alert': instance.alert,
      'editedAt': const TimestampConverter().toJson(instance.editedAt),
      'editedBy': instance.editedBy,
      'editorName': instance.editorName,
    };
