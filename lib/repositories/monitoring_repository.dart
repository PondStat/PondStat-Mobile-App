import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase/firestore_helper.dart';

class MonitoringRepository {
  static final MonitoringRepository _instance = MonitoringRepository._internal();
  factory MonitoringRepository() => _instance;
  MonitoringRepository._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Saves a new measurement to Firestore and logs it to history.
  Future<String> saveMeasurement({
    required String pondId,
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
    required DateTime selectedDay,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final String dateKey = "${selectedDay.year}-${selectedDay.month}-${selectedDay.day}";
    final batch = _firestore.batch();
    final measurementRef = FirestoreHelper.measurementsCollection.doc();

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
    };

    batch.set(measurementRef, measurementData);

    _logHistory(
      batch: batch,
      pondId: pondId,
      measurementId: measurementRef.id,
      parameter: label,
      action: 'create',
      before: null,
      after: {'value': averageValue, 'pointValues': pointValues},
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
    final measurementRef = FirestoreHelper.measurementsCollection.doc(measurementId);

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

  /// Updates multiple measurements in a single batch and logs them to history.
  Future<void> updateMeasurements({
    required String pondId,
    required List<DocumentSnapshot> docs,
    required Map<String, Map<String, double>> updatedValues,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final batch = _firestore.batch();

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final newPoints = updatedValues[doc.id];
      if (newPoints == null) continue;

      final double avg = double.parse(
        (newPoints.values.reduce((a, b) => a + b) / newPoints.length)
            .toStringAsFixed(2),
      );

      batch.update(doc.reference, {
        'pointValues': newPoints,
        'value': avg,
      });

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

  /// Adds a new custom parameter to Firestore.
  Future<void> addCustomParameter({
    required String label,
    required String unit,
    required String type,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    await FirestoreHelper.customParametersCollection.add({
      'label': label,
      'unit': unit,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': currentUser!.uid,
    });
  }

  /// Deletes a custom parameter from Firestore.
  Future<void> deleteCustomParameter(String parameterId) async {
    if (currentUser == null) throw Exception('User not authenticated');
    await FirestoreHelper.customParametersCollection.doc(parameterId).delete();
  }

  /// Saves or updates a job schedule for a member.
  Future<void> saveJobSchedule({
    required String pondId,
    required String userId,
    required String userName,
    required String jobTitle,
    required List<int> scheduledDays,
    required List<String> startTimes,
    String? description,
  }) async {
    if (currentUser == null) throw Exception('User not authenticated');

    final docId = "${pondId}_$userId";
    await FirestoreHelper.schedulesCollection.doc(docId).set({
      'pondId': pondId,
      'userId': userId,
      'userName': userName,
      'jobTitle': jobTitle,
      'scheduledDays': scheduledDays,
      'startTime': startTimes.isNotEmpty ? startTimes.first : '', // Backward compatibility
      'startTimes': startTimes,
      'description': description,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': currentUser!.uid,
    });
  }

  /// Fetches a job schedule for a specific user in a pond.
  Future<Map<String, dynamic>?> getJobSchedule(String pondId, String userId) async {
    final docId = "${pondId}_$userId";
    final doc = await FirestoreHelper.schedulesCollection.doc(docId).get();
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

    await FirestoreHelper.expensesCollection.add({
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
    await FirestoreHelper.expensesCollection.doc(expenseId).delete();
  }

  /// Stream of expenses for a pond.
  Stream<QuerySnapshot<Map<String, dynamic>>> getExpensesStream(String pondId) {
    return FirestoreHelper.expensesCollection
        .where('pondId', isEqualTo: pondId)
        .orderBy('timestamp', descending: true)
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
    final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
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
