import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'pond_sale.freezed.dart';
part 'pond_sale.g.dart';

@freezed
abstract class PondSale with _$PondSale {
  const factory PondSale({
    @Default('') String id,
    required String pondId,
    required String buyerName,
    required String productName,
    @Default(0.0) double quantity,
    @Default('kg') String unit,
    @Default(0.0) double pricePerUnit,
    @Default(0.0) double totalAmount,
    @Default('') String recordedById,
    @Default('Unknown') String recordedByName,
    @TimestampConverter() DateTime? timestamp,
    @Default('') String notes,
  }) = _PondSale;

  factory PondSale.fromJson(Map<String, dynamic> json) =>
      _$PondSaleFromJson(json);
}
