import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clock/clock.dart';
import 'package:pondstat/core/config/env.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

/// {@template firestore_helper}
/// **DEPRECATED**: This class is a backward-compatible shim that exists solely
/// to bridge legacy UI code that hasn't yet been migrated to the Repository
/// pattern. **Do NOT add new usages of this class.**
///
/// New code should inject repositories via Riverpod providers:
/// - `monitoringRepositoryProvider` for measurements, expenses, schedules
/// - `authRepositoryProvider` / `notificationsRepositoryProvider` for users
/// - `pondRepositoryProvider` for ponds
/// - `growthRepositoryProvider` for growth data
/// {@endtemplate}
@Deprecated('Use Riverpod Repositories instead. See class docstring.')
class FirestoreHelper {
  static final String appId = Env.appId;

  static final DocumentReference<Map<String, dynamic>> _baseRef =
      FirebaseFirestore.instance
          .collection('artifacts')
          .doc(appId)
          .collection('public')
          .doc('data');

  static final CollectionReference<Map<String, dynamic>> usersCollection =
      _baseRef.collection('users');

  static final CollectionReference<Map<String, dynamic>>
  measurementsCollection = _baseRef.collection('measurements');

  static final CollectionReference<Map<String, dynamic>> pondsCollection =
      _baseRef.collection('ponds');

  static final CollectionReference<Map<String, dynamic>>
  customParametersCollection = _baseRef.collection('custom_parameters');

  static final CollectionReference<Map<String, dynamic>>
  measurementHistoryCollection = _baseRef.collection('measurement_history');

  static final CollectionReference<Map<String, dynamic>> schedulesCollection =
      _baseRef.collection('schedules');

  static final CollectionReference<Map<String, dynamic>> expensesCollection =
      _baseRef.collection('expenses');

  /// Uses [clock.now()] for testable time instead of [DateTime.now()].
  static Query<Map<String, dynamic>> getHistoricalMeasurements(
    String pondId,
    int days,
  ) {
    final DateTime cutoff = clock.now().subtract(Duration(days: days));
    return measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: false);
  }

  /// Uses [DateTimeX.toEndOfDay()] extension instead of manual boilerplate.
  static Query<Map<String, dynamic>> getMeasurementsByDateRange(
    String pondId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate.toEndOfDay()),
        )
        .orderBy('timestamp', descending: false);
  }
}
