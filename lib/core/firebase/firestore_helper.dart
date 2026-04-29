import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  static const String appId = 'pondstat-app-v1';

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

  static Query<Map<String, dynamic>> getHistoricalMeasurements(
    String pondId,
    int days,
  ) {
    final DateTime cutoff = DateTime.now().subtract(Duration(days: days));
    return measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: false);
  }

  static Query<Map<String, dynamic>> getMeasurementsByDateRange(
    String pondId,
    DateTime startDate,
    DateTime endDate,
  ) {
    // End date should include the full day
    final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .orderBy('timestamp', descending: false);
  }
}
