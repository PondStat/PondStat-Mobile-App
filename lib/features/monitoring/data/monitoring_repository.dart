import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clock/clock.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';

part 'monitoring_repository.g.dart';

@riverpod
MonitoringRepository monitoringRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  return MonitoringRepository(baseRef, firestore, auth);
}

class MonitoringRepository {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MonitoringRepository(this._baseRef, this._firestore, this._auth);

  User? get currentUser => _auth.currentUser;

  // ─── Collection References ───────────────────────────────────────────
  // These replace all the static references that were in FirestoreHelper.

  CollectionReference<Map<String, dynamic>> get measurementsCollection =>
      _baseRef.collection('measurements');

  CollectionReference<Map<String, dynamic>> get measurementHistoryCollection =>
      _baseRef.collection('measurement_history');

  CollectionReference<Map<String, dynamic>> get customParametersCollection =>
      _baseRef.collection('custom_parameters');

  CollectionReference<Map<String, dynamic>> get schedulesCollection =>
      _baseRef.collection('schedules');

  CollectionReference<Map<String, dynamic>> get expensesCollection =>
      _baseRef.collection('expenses');

  // ─── Historical Queries (with clock for testable time) ───────────────

  /// Returns a paginated query for historical measurements.
  /// Uses [clock.now()] instead of [DateTime.now()] for testability.
  Query<Map<String, dynamic>> getHistoricalMeasurements(
    String pondId,
    int days, {
    int limit = 500,
    DocumentSnapshot? startAfter,
  }) {
    final DateTime cutoff = clock.now().subtract(Duration(days: days));
    Query<Map<String, dynamic>> query = measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff))
        .orderBy('timestamp', descending: false)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query;
  }

  /// Returns a paginated query for measurements in a specific date range.
  /// Uses [DateTimeX.toEndOfDay()] extension to eliminate boilerplate.
  Query<Map<String, dynamic>> getMeasurementsByDateRange(
    String pondId,
    DateTime startDate,
    DateTime endDate, {
    int limit = 500,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate.toEndOfDay()),
        )
        .orderBy('timestamp', descending: false)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query;
  }

  // ─── CRUD Operations ────────────────────────────────────────────────

  /// Saves a new measurement to Firestore and logs it to history.
  Future<String> saveMeasurement({
    required String pondId,
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
    required Map<String, List<double>> replicateValues,
    required DateTime selectedDay,
    String? notes,
    Map<String, dynamic>? alert,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final String dateKey =
        "${selectedDay.year}-${selectedDay.month}-${selectedDay.day}";
    final batch = _firestore.batch();
    final measurementRef = measurementsCollection.doc();

    final measurementData = {
      'pondId': pondId,
      'dateKey': dateKey,
      'timestamp': Timestamp.fromDate(selectedDay),
      'recordedAt': FieldValue.serverTimestamp(),
      'recordedBy': currentUser!.uid,
      'recorderName': currentUser!.displayName ?? 'Unknown',
      'type': type,
      'parameter': label,
      'value': averageValue,
      'unit': unit,
      'timeString': timeString,
      'pointValues': pointValues,
      'replicateValues': replicateValues,
      'notes': (notes?.isNotEmpty == true) ? notes : null,
      'alert': alert,
    }..removeWhere((key, value) => value == null);

    batch.set(measurementRef, measurementData);

    _logHistory(
      batch: batch,
      pondId: pondId,
      measurementId: measurementRef.id,
      parameter: label,
      action: 'create',
      before: null,
      after: {
        'value': averageValue,
        'pointValues': pointValues,
        'replicateValues': replicateValues,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    await batch.commit();
    return measurementRef.id;
  }

  /// Deletes a measurement from Firestore and logs it to history.
  Future<void> deleteMeasurement({
    required String pondId,
    required String measurementId,
    required Map<String, dynamic> currentData,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();
    final measurementRef = measurementsCollection.doc(measurementId);

    batch.delete(measurementRef);

    _logHistory(
      batch: batch,
      pondId: pondId,
      measurementId: measurementId,
      parameter: currentData['parameter'],
      action: 'delete',
      before: currentData,
      after: null,
    );

    await batch.commit();
  }

  /// Deletes a list/group of measurements from Firestore in a batch and logs to history.
  Future<void> deleteMeasurementsGroup({
    required String pondId,
    required List<DocumentSnapshot> docs,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (var doc in docs) {
      final data = doc.data();
      if (data is! Map<String, dynamic>) continue;

      batch.delete(doc.reference);

      _logHistory(
        batch: batch,
        pondId: pondId,
        measurementId: doc.id,
        parameter: data['parameter'],
        action: 'delete',
        before: {
          'value': data['value'],
          'pointValues': data['pointValues'] ?? {},
        },
        after: null,
      );
    }

    await batch.commit();
  }

  /// Clears all input values (pointValues, replicateValues, value, notes) for a group of measurements.
  Future<void> clearMeasurementsGroupInputs({
    required String pondId,
    required List<DocumentSnapshot> docs,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (var doc in docs) {
      final data = doc.data();
      if (data is! Map<String, dynamic>) continue;

      final updateData = {
        'pointValues': <String, double>{},
        'replicateValues': <String, List<double>>{},
        'value': null,
        'notes': null,
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': currentUser?.uid,
        'editorName': currentUser?.displayName ?? 'Unknown',
      };

      batch.update(doc.reference, updateData);

      // Log to history
      final historyRef = measurementHistoryCollection.doc();
      batch.set(historyRef, {
        'pondId': pondId,
        'measurementId': doc.id,
        'parameter': data['parameter'],
        'action': 'clear_inputs',
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': currentUser?.uid,
        'editorName': currentUser?.displayName ?? 'Unknown',
        'before': {
          'value': data['value'],
          'pointValues': data['pointValues'],
          'replicateValues': data['replicateValues'],
          'notes': data['notes'],
        },
        'after': updateData,
      });
    }

    await batch.commit();
  }

  /// Updates multiple measurements in a single batch and logs them to history.
  Future<void> updateMeasurements({
    required String pondId,
    required List<DocumentSnapshot> docs,
    required Map<String, Map<String, double>> updatedValues,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (var doc in docs) {
      final data = doc.data();
      if (data is! Map<String, dynamic>) continue;
      final newPoints = updatedValues[doc.id];
      if (newPoints == null) continue;

      final double avg = double.parse(
        (newPoints.values.reduce((a, b) => a + b) / newPoints.length)
            .toStringAsFixed(2),
      );

      batch.update(doc.reference, {'pointValues': newPoints, 'value': avg});

      _logHistory(
        batch: batch,
        pondId: pondId,
        measurementId: doc.id,
        parameter: data['parameter'],
        action: 'update',
        before: {'value': data['value'], 'pointValues': data['pointValues']},
        after: {'value': avg, 'pointValues': newPoints},
      );
    }

    await batch.commit();
  }

  /// Updates measurements with replicate values and calculates point averages.
  Future<void> updateMeasurementsWithReplicates({
    required String pondId,
    required List<DocumentSnapshot> docs,
    required Map<String, Map<String, double>> updatedPointValues,
    required Map<String, Map<String, List<double>>> updatedReplicateValues,
    Map<String, String?>? updatedNotes,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (var doc in docs) {
      final data = doc.data();
      if (data is! Map<String, dynamic>) continue;
      final newPointValues = updatedPointValues[doc.id];
      final newReplicateValues = updatedReplicateValues[doc.id];
      final newNote = updatedNotes?[doc.id];

      if (newPointValues == null || newReplicateValues == null) continue;

      final double? avg = newPointValues.isNotEmpty
          ? double.parse(
              (newPointValues.values.reduce((a, b) => a + b) /
                      newPointValues.length)
                  .toStringAsFixed(2),
            )
          : null;

      final updateData = {
        'pointValues': newPointValues,
        'replicateValues': newReplicateValues,
        'value': avg,
        'notes': newNote,
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': currentUser?.uid,
        'editorName': currentUser?.displayName ?? 'Unknown',
      };

      batch.update(doc.reference, updateData);

      // History logging
      final historyRef = measurementHistoryCollection.doc();
      batch.set(historyRef, {
        'pondId': pondId,
        'measurementId': doc.id,
        'parameter': data['parameter'],
        'action': 'update',
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': currentUser?.uid,
        'editorName': currentUser?.displayName ?? 'Unknown',
        'before': {
          'value': data['value'],
          'pointValues': data['pointValues'],
          'replicateValues': data['replicateValues'],
          'notes': data['notes'],
        },
        'after': updateData,
      });
    }

    await batch.commit();
  }

  /// Adds a new custom parameter to Firestore.
  Future<void> addCustomParameter({
    required String label,
    required String unit,
    required String type,
    required String category,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await customParametersCollection.add({
      'label': label,
      'unit': unit,
      'type': type,
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser!.uid,
    });
  }

  /// Deletes a custom parameter from Firestore.
  Future<void> deleteCustomParameter(String parameterId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await customParametersCollection.doc(parameterId).delete();
  }

  /// Saves or updates a job schedule for a member.
  Future<void> saveJobSchedule({
    required String pondId,
    required String userId,
    required String userName,
    required Map<String, dynamic> schedule,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final docId = "${pondId}_$userId";
    await schedulesCollection.doc(docId).set({
      'pondId': pondId,
      'userId': userId,
      'userName': userName,
      'schedule': schedule,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUser!.uid,
    });
  }

  /// Fetches a job schedule for a specific user in a pond.
  Future<Map<String, dynamic>?> getJobSchedule(
    String pondId,
    String userId,
  ) async {
    final docId = "${pondId}_$userId";
    final doc = await schedulesCollection.doc(docId).get();
    return doc.exists ? doc.data() : null;
  }

  /// Adds a new expense to Firestore.
  Future<void> addExpense({
    required String pondId,
    required String item,
    required int quantity,
    required double amountPerItem,
    required double totalAmount,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await expensesCollection.add({
      'pondId': pondId,
      'item': item,
      'quantity': quantity,
      'amountPerItem': amountPerItem,
      'totalAmount': totalAmount,
      'buyerId': currentUser!.uid,
      'buyerName': currentUser!.displayName ?? 'Unknown',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes an expense from Firestore.
  Future<void> deleteExpense(String expenseId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await expensesCollection.doc(expenseId).delete();
  }

  /// Stream of expenses for a pond.
  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesStream(String pondId) {
    return expensesCollection
        .where('pondId', isEqualTo: pondId)
        .snapshots();
  }

  void _logHistory({
    required WriteBatch batch,
    required String pondId,
    required String measurementId,
    required String parameter,
    required String action,
    required Map<String, dynamic>? before,
    required Map<String, dynamic>? after,
  }) {
    final historyRef = measurementHistoryCollection.doc();
    batch.set(historyRef, {
      'pondId': pondId,
      'measurementId': measurementId,
      'parameter': parameter,
      'action': action,
      'editedAt': FieldValue.serverTimestamp(),
      'editedBy': currentUser?.uid,
      'editorName': currentUser?.displayName ?? 'Unknown',
      'before': before,
      'after': after,
    });
  }
}
