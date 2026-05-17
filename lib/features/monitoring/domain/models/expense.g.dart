// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Expense _$ExpenseFromJson(Map<String, dynamic> json) => _Expense(
  id: json['id'] as String? ?? '',
  pondId: json['pondId'] as String,
  item: json['item'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 0,
  amountPerItem: (json['amountPerItem'] as num?)?.toDouble() ?? 0.0,
  totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
  buyerId: json['buyerId'] as String? ?? '',
  buyerName: json['buyerName'] as String? ?? 'Unknown',
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
);

Map<String, dynamic> _$ExpenseToJson(_Expense instance) => <String, dynamic>{
  'id': instance.id,
  'pondId': instance.pondId,
  'item': instance.item,
  'quantity': instance.quantity,
  'amountPerItem': instance.amountPerItem,
  'totalAmount': instance.totalAmount,
  'buyerId': instance.buyerId,
  'buyerName': instance.buyerName,
  'timestamp': const TimestampConverter().toJson(instance.timestamp),
};
