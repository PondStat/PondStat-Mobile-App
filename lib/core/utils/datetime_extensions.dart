import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

extension DateTimeX on DateTime {
  /// Returns a new DateTime set to the end of the current day (23:59:59.999).
  DateTime toEndOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Returns a new DateTime set to the start of the current day (00:00:00.000).
  DateTime toStartOfDay() {
    return DateTime(year, month, day, 0, 0, 0, 0);
  }

  /// Returns a new UTC DateTime set to midnight (00:00:00.000) of this day.
  DateTime toUtcMidnight() {
    return DateTime.utc(year, month, day, 0, 0, 0, 0);
  }

  /// Returns a new UTC DateTime set to the end of this day (23:59:59.999).
  DateTime toUtcEndOfDay() {
    return DateTime.utc(year, month, day, 23, 59, 59, 999);
  }
}

/// A JsonConverter that maps Firestore's [Timestamp] to Dart's [DateTime].
class TimestampConverter implements JsonConverter<DateTime?, Object?> {
  const TimestampConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json == null) return null;
    if (json is Timestamp) return json.toDate();
    // Sometimes when parsing locally (e.g., from cache or string representations)
    // it might come as an int (milliseconds) or String.
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json);
    if (json is String) return DateTime.tryParse(json);
    return null;
  }

  @override
  Object? toJson(DateTime? object) {
    if (object == null) return null;
    // We typically want to save it as a FieldValue.serverTimestamp() upon creation,
    // but for updates, this serializes it to a Firestore Timestamp.
    return Timestamp.fromDate(object);
  }
}
