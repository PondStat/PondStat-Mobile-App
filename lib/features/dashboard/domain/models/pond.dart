import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart'; // We'll create a custom converter

part 'pond.freezed.dart';
part 'pond.g.dart';

@freezed
abstract class Pond with _$Pond {
  const Pond._();
  const factory Pond({
    required String id,
    @Default('') String name,
    @Default('') String species,
    @Default(0) int stockingQuantity,
    @Default(0) int targetCulturePeriodDays,
    @Default('') String ownerId,
    @Default([]) List<String> memberIds,
    @Default({}) Map<String, String> roles,
    @TimestampConverter() DateTime? createdAt,
  }) = _Pond;

  factory Pond.fromJson(Map<String, dynamic> json) => _$PondFromJson(json);
  
  // Custom factory to inject document ID from Firestore if needed
  factory Pond.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    data['id'] = doc.id; // Ensure ID is parsed
    return Pond.fromJson(data);
  }
}
