import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    @Default('') String id,
    required String pondId,
    required String item,
    @Default(0) int quantity,
    @Default(0.0) double amountPerItem,
    @Default(0.0) double totalAmount,
    @Default('') String buyerId,
    @Default('Unknown') String buyerName,
    @TimestampConverter() DateTime? timestamp,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);
}
