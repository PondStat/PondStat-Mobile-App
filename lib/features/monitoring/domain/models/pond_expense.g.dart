// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pond_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PondExpense _$PondExpenseFromJson(Map<String, dynamic> json) => _PondExpense(
  id: json['id'] as String? ?? '',
  pondId: json['pondId'] as String,
  category: json['category'] as String,
  item: json['item'] as String,
  quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
  unit: json['unit'] as String? ?? '',
  amountPerUnit: (json['amountPerUnit'] as num?)?.toDouble() ?? 0.0,
  totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
  recordedById: json['recordedById'] as String? ?? '',
  recordedByName: json['recordedByName'] as String? ?? 'Unknown',
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
  notes: json['notes'] as String? ?? '',
);

Map<String, dynamic> _$PondExpenseToJson(_PondExpense instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pondId': instance.pondId,
      'category': instance.category,
      'item': instance.item,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'amountPerUnit': instance.amountPerUnit,
      'totalAmount': instance.totalAmount,
      'recordedById': instance.recordedById,
      'recordedByName': instance.recordedByName,
      'timestamp': const TimestampConverter().toJson(instance.timestamp),
      'notes': instance.notes,
    };
