import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:clock/clock.dart';
import 'package:pondstat/core/utils/datetime_extensions.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';

import 'package:pondstat/core/firebase/offline_repository_mixin.dart';

part 'monitoring_repository.g.dart';

@riverpod
MonitoringRepository monitoringRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);
  final auth = ref.watch(firebaseAuthProvider);
  final isOffline = ref.watch(isOfflineProvider);
  return MonitoringRepository(
    baseRef,
    firestore,
    auth,
    isOffline: () => isOffline,
  );
}

class MonitoringRepository with OfflineRepositoryMixin {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  @override
  final bool Function() isOffline;

  MonitoringRepository(
    this._baseRef,
    this._firestore,
    this._auth, {
    required this.isOffline,
  });

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
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate.toUtcMidnight()),
        )
        .where(
          'timestamp',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate.toUtcEndOfDay()),
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

    // Validate that the parameter has not already been recorded for this day
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final existing = await measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('type', isEqualTo: type)
        .where('dateKey', isEqualTo: dateKey)
        .where('parameter', isEqualTo: label)
        .get(GetOptions(source: source));

    if (existing.docs.isNotEmpty) {
      throw Exception("Parameter '$label' has already been recorded for this day.");
    }

    final batch = _firestore.batch();
    final String docId = "${pondId}_${label.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${dateKey}_$type";
    final measurementRef = measurementsCollection.doc(docId);

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

    final String historyAction = (type == 'growth') ? 'growth_create' : 'create';

    _logHistory(
      batch: batch,
      pondId: pondId,
      measurementId: measurementRef.id,
      parameter: label,
      action: historyAction,
      before: null,
      after: {
        'value': averageValue,
        'pointValues': pointValues,
        'replicateValues': replicateValues,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    if (alert != null) {
      _logHistory(
        batch: batch,
        pondId: pondId,
        measurementId: measurementRef.id,
        parameter: label,
        action: 'alert',
        before: null,
        after: {
          'tier': alert['tier'],
          'title': alert['title'],
          'body': alert['body'],
          'value': averageValue,
        },
      );
    }

    await commitBatchWithTimeout(batch);
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

    await commitBatchWithTimeout(batch);
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

    await commitBatchWithTimeout(batch);
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

    await commitBatchWithTimeout(batch);
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

      final isGrowth = data['type'] == 'growth';
      final historyAction = isGrowth ? 'growth_update' : 'update';

      _logHistory(
        batch: batch,
        pondId: pondId,
        measurementId: doc.id,
        parameter: data['parameter'],
        action: historyAction,
        before: {'value': data['value'], 'pointValues': data['pointValues']},
        after: {'value': avg, 'pointValues': newPoints},
      );
    }

    await commitBatchWithTimeout(batch);
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

      final isGrowth = data['type'] == 'growth';
      final historyAction = isGrowth ? 'growth_update' : 'update';

      _logHistory(
        batch: batch,
        pondId: pondId,
        measurementId: doc.id,
        parameter: data['parameter'],
        action: historyAction,
        before: {
          'value': data['value'],
          'pointValues': data['pointValues'],
          'replicateValues': data['replicateValues'],
          'notes': data['notes'],
        },
        after: updateData,
      );
    }

    await commitBatchWithTimeout(batch);
  }



  /// Adds a new custom parameter to Firestore.
  Future<void> addCustomParameter({
    required String label,
    required String unit,
    required String type,
    required String category,
    required String pondId,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await runWrite(() async {
      await customParametersCollection.add({
        'label': label,
        'unit': unit,
        'type': type,
        'category': category,
        'pondId': pondId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': currentUser!.uid,
      });
    });
  }

  /// Deletes a custom parameter from Firestore.
  Future<void> deleteCustomParameter(String parameterId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await runWrite(() => customParametersCollection.doc(parameterId).delete());
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
    await runWrite(() => schedulesCollection.doc(docId).set({
      'pondId': pondId,
      'userId': userId,
      'userName': userName,
      'schedule': schedule,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUser!.uid,
    }));
  }

  /// Fetches a job schedule for a specific user in a pond.
  Future<Map<String, dynamic>?> getJobSchedule(
    String pondId,
    String userId,
  ) async {
    final docId = "${pondId}_$userId";
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final doc = await schedulesCollection.doc(docId).get(GetOptions(source: source));
    return doc.exists ? doc.data() : null;
  }

  /// Fetches the last recorded measurement for a specific parameter in a pond.
  Future<Map<String, dynamic>?> getLastRecordedValues({
    required String pondId,
    required String label,
  }) async {
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final querySnapshot = await measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('parameter', isEqualTo: label)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get(GetOptions(source: source));
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first.data();
    }
    return null;
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
