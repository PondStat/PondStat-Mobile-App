import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'pond_expense.freezed.dart';
part 'pond_expense.g.dart';

@freezed
abstract class PondExpense with _$PondExpense {
  const factory PondExpense({
    @Default('') String id,
    required String pondId,
    required String category,
    required String item,
    @Default(0.0) double quantity,
    @Default('') String unit,
    @Default(0.0) double amountPerUnit,
    @Default(0.0) double totalAmount,
    @Default('') String recordedById,
    @Default('Unknown') String recordedByName,
    @TimestampConverter() DateTime? timestamp,
    @Default('') String notes,
  }) = _PondExpense;

  factory PondExpense.fromJson(Map<String, dynamic> json) =>
      _$PondExpenseFromJson(json);
}
