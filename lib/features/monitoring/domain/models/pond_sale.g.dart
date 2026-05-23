// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pond_sale.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PondSale _$PondSaleFromJson(Map<String, dynamic> json) => _PondSale(
  id: json['id'] as String? ?? '',
  pondId: json['pondId'] as String,
  buyerName: json['buyerName'] as String,
  productName: json['productName'] as String,
  quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
  unit: json['unit'] as String? ?? 'kg',
  pricePerUnit: (json['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
  totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
  recordedById: json['recordedById'] as String? ?? '',
  recordedByName: json['recordedByName'] as String? ?? 'Unknown',
  timestamp: const TimestampConverter().fromJson(json['timestamp']),
  notes: json['notes'] as String? ?? '',
);

Map<String, dynamic> _$PondSaleToJson(_PondSale instance) => <String, dynamic>{
  'id': instance.id,
  'pondId': instance.pondId,
  'buyerName': instance.buyerName,
  'productName': instance.productName,
  'quantity': instance.quantity,
  'unit': instance.unit,
  'pricePerUnit': instance.pricePerUnit,
  'totalAmount': instance.totalAmount,
  'recordedById': instance.recordedById,
  'recordedByName': instance.recordedByName,
  'timestamp': const TimestampConverter().toJson(instance.timestamp),
  'notes': instance.notes,
};
