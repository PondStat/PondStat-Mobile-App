import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';

import 'package:pondstat/core/firebase/offline_repository_mixin.dart';

part 'growth_repository.g.dart';

class GrowthMetrics {
  final DateTime date;
  final int weekNumber;
  final double? abw;
  final double? adg;
  final double? fcr;
  final double? dfr;
  final double totalWeight;
  final double sampleCount;
  final double feedingRate;
  final double feedConsumed;
  final double weightGained;
  final String? abwDocId;
  final String? adgDocId;
  final String? dfrDocId;
  final String? fcrDocId;
  final String? recorderName;
  final String? editorName;
  final String? notes;

  GrowthMetrics({
    required this.date,
    required this.weekNumber,
    this.abw,
    this.adg,
    this.fcr,
    this.dfr,
    this.totalWeight = 0.0,
    this.sampleCount = 0.0,
    this.feedingRate = 0.0,
    this.feedConsumed = 0.0,
    this.weightGained = 0.0,
    this.abwDocId,
    this.adgDocId,
    this.dfrDocId,
    this.fcrDocId,
    this.recorderName,
    this.editorName,
    this.notes,
  });
}

@riverpod
GrowthRepository growthRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  final isOffline = ref.watch(isOfflineProvider);
  return GrowthRepository(
    baseRef,
    isOffline: () => isOffline,
  );
}

class GrowthRepository with OfflineRepositoryMixin {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  @override
  final bool Function() isOffline;

  GrowthRepository(
    this._baseRef, {
    required this.isOffline,
  });

  // ─── Collection References ───────────────────────────────────────────
  CollectionReference<Map<String, dynamic>> get pondsCollection =>
      _baseRef.collection('ponds');

  CollectionReference<Map<String, dynamic>> get measurementsCollection =>
      _baseRef.collection('measurements');

  CollectionReference<Map<String, dynamic>> get measurementHistoryCollection =>
      _baseRef.collection('measurement_history');

  Future<List<GrowthMetrics>> calculateGrowthMetrics(
    String pondId,
  ) async {
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final pondDoc = await pondsCollection.doc(pondId).get(GetOptions(source: source));
    if (!pondDoc.exists) return [];

    final pondData = pondDoc.data() ?? {};
    final int fishCount = (pondData['stockingQuantity'] as num?)?.toInt() ?? 0;

    final relevantParams = [
      ParameterNames.totalWeightSampled,
      ParameterNames.numFishSampled,
      ParameterNames.feedingRate,
      ParameterNames.totalFeedConsumed,
      ParameterNames.totalWeightGained,
      ParameterNames.abw,
      ParameterNames.adg,
      ParameterNames.dfr,
      ParameterNames.fcr,
    ];

    final allDocs = await _fetchRelevantMeasurements(pondId, relevantParams);
    if (allDocs.isEmpty) return [];

    DateTime pondStartDate;
    if (pondData['createdAt'] != null) {
      pondStartDate = (pondData['createdAt'] as Timestamp).toDate();
    } else {
      final fallbackTimestamp = allDocs.first.data()!['timestamp'] as Timestamp?;
      pondStartDate = fallbackTimestamp?.toDate() ?? DateTime.now();
    }

    final weeklyBuckets = _bucketizeByWeek(allDocs, pondStartDate);

    return _calculateWeeklyMetrics(weeklyBuckets, fishCount);
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>>
  _fetchRelevantMeasurements(String pondId, List<String> relevantParams) async {
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final measurementsSnapshot = await measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .get(GetOptions(source: source));

    return measurementsSnapshot.docs
        .where((doc) => relevantParams.contains(doc.data()['parameter']))
        .toList()
      ..sort((a, b) {
        final tA = a.data()['timestamp'] as Timestamp?;
        final tB = b.data()['timestamp'] as Timestamp?;
        if (tA == null || tB == null) return 0;
        return tA.compareTo(tB);
      });
  }

  Map<int, Map<String, dynamic>> _bucketizeByWeek(
    List<DocumentSnapshot<Map<String, dynamic>>> allDocs,
    DateTime pondStartDate,
  ) {
    final Map<int, Map<String, dynamic>> weeklyBuckets = {};

    for (var doc in allDocs) {
      final data = doc.data()!;
      if (data['timestamp'] == null || data['value'] == null) continue;

      final date = (data['timestamp'] as Timestamp).toDate();
      final val = (data['value'] as num).toDouble();
      final param = data['parameter'] as String;

      final int daysSinceStart = date.difference(pondStartDate).inDays;
      final int weekNumber = (daysSinceStart / 7).floor() + 1;
      final int displayWeek = weekNumber > 0 ? weekNumber : 1;

      weeklyBuckets.putIfAbsent(
        displayWeek,
        () => {
          'date': date,
          'notes': <String>[],
          ParameterNames.totalWeightSampled: 0.0,
          ParameterNames.numFishSampled: 0.0,
          ParameterNames.feedingRate: 0.0,
          ParameterNames.totalFeedConsumed: 0.0,
          ParameterNames.totalWeightGained: 0.0,
          ParameterNames.abw: 0.0,
          ParameterNames.adg: 0.0,
          ParameterNames.dfr: 0.0,
          ParameterNames.fcr: 0.0,
        },
      );

      weeklyBuckets[displayWeek]!['date'] = date;
      weeklyBuckets[displayWeek]![param] = val;

      final note = data['notes'] as String?;
      if (note != null && note.trim().isNotEmpty) {
        final list = weeklyBuckets[displayWeek]!['notes'] as List<String>? ?? <String>[];
        final trimmed = note.trim();
        if (!list.contains(trimmed)) {
          list.add(trimmed);
        }
        weeklyBuckets[displayWeek]!['notes'] = list;
      }

      if (param == ParameterNames.totalWeightSampled) {
        weeklyBuckets[displayWeek]!['weightDocId'] = doc.id;
      } else if (param == ParameterNames.numFishSampled) {
        weeklyBuckets[displayWeek]!['countDocId'] = doc.id;
      } else if (param == ParameterNames.abw) {
        weeklyBuckets[displayWeek]!['abwDocId'] = doc.id;
      } else if (param == ParameterNames.adg) {
        weeklyBuckets[displayWeek]!['adgDocId'] = doc.id;
      } else if (param == ParameterNames.dfr) {
        weeklyBuckets[displayWeek]!['dfrDocId'] = doc.id;
      } else if (param == ParameterNames.fcr) {
        weeklyBuckets[displayWeek]!['fcrDocId'] = doc.id;
      }

      weeklyBuckets[displayWeek]!['recorderName'] =
          data['recorderName'] as String? ??
          weeklyBuckets[displayWeek]!['recorderName'] ??
          'Unknown';
      if (data['editorName'] != null) {
        weeklyBuckets[displayWeek]!['editorName'] = data['editorName'];
      }
    }
    return weeklyBuckets;
  }

  List<GrowthMetrics> _calculateWeeklyMetrics(
    Map<int, Map<String, dynamic>> weeklyBuckets,
    int fishCount,
  ) {
    final sortedWeeks = weeklyBuckets.keys.toList()..sort();
    final List<GrowthMetrics> metrics = [];

    for (int i = 0; i < sortedWeeks.length; i++) {
      final week = sortedWeeks[i];
      final bucket = weeklyBuckets[week]!;

      final double totalWeight = bucket[ParameterNames.totalWeightSampled];
      final double sampleCount = bucket[ParameterNames.numFishSampled];
      final double feedingRate = bucket[ParameterNames.feedingRate];
      final double feedConsumed = bucket[ParameterNames.totalFeedConsumed];
      final double weightGained = bucket[ParameterNames.totalWeightGained];

      final double explicitAbw = bucket[ParameterNames.abw];
      final double explicitAdg = bucket[ParameterNames.adg];
      final double explicitDfr = bucket[ParameterNames.dfr];
      final double explicitFcr = bucket[ParameterNames.fcr];

      final double? currentAbw = explicitAbw > 0
          ? explicitAbw
          : (sampleCount > 0 ? totalWeight / sampleCount : null);

      double? adg = explicitAdg > 0 ? explicitAdg : null;
      double? dfr = explicitDfr > 0
          ? explicitDfr
          : (currentAbw != null && feedingRate > 0 && fishCount > 0
              ? (currentAbw * fishCount * feedingRate / 100.0)
              : null);
      double? fcr = explicitFcr > 0
          ? explicitFcr
          : (weightGained > 0 && feedConsumed > 0 ? feedConsumed / weightGained : null);

      if (i > 0 && explicitAdg == 0.0) {
        final prevWeek = sortedWeeks[i - 1];
        final prevBucket = weeklyBuckets[prevWeek]!;

        final prevTotalWeight =
            prevBucket[ParameterNames.totalWeightSampled] as double;
        final prevSampleCount =
            prevBucket[ParameterNames.numFishSampled] as double;
        final prevExplicitAbw = prevBucket[ParameterNames.abw] as double;

        final double? prevAbw = prevExplicitAbw > 0
            ? prevExplicitAbw
            : (prevSampleCount > 0 ? prevTotalWeight / prevSampleCount : null);

        final DateTime currentDate = bucket['date'] as DateTime;
        final DateTime prevDate = prevBucket['date'] as DateTime;
        final int daysBetween = currentDate.difference(prevDate).inDays;

        if (daysBetween > 0 && currentAbw != null && prevAbw != null && currentAbw > 0 && prevAbw > 0) {
          adg = (currentAbw - prevAbw) / daysBetween;
        }
      }

      final notesList = bucket['notes'] as List<String>? ?? const <String>[];
      final String? combinedNotes = notesList.isNotEmpty ? notesList.join('\n') : null;

      metrics.add(
        GrowthMetrics(
          date: bucket['date'] as DateTime,
          weekNumber: week,
          abw: _round(currentAbw, 1),
          adg: _round(adg, 2),
          fcr: _round(fcr, 2),
          dfr: _round(dfr, 2),
          totalWeight: totalWeight,
          sampleCount: sampleCount,
          feedingRate: feedingRate,
          feedConsumed: feedConsumed,
          weightGained: weightGained,
          abwDocId:
              bucket['abwDocId'] as String? ?? bucket['weightDocId'] as String?,
          adgDocId: bucket['adgDocId'] as String?,
          dfrDocId: bucket['dfrDocId'] as String?,
          fcrDocId: bucket['fcrDocId'] as String?,
          recorderName: bucket['recorderName'] as String?,
          editorName: bucket['editorName'] as String?,
          notes: combinedNotes,
        ),
      );
    }

    return metrics.reversed.toList();
  }

  static double? _round(double? value, int places) {
    if (value == null) return null;
    return double.parse(value.toStringAsFixed(places));
  }

  Future<void> deleteGrowthSampling(
    GrowthMetrics m,
    User? user,
    String pondId,
  ) async {
    final docIds = [
      m.abwDocId,
      m.adgDocId,
      m.dfrDocId,
      m.fcrDocId,
    ].whereType<String>().toList();
    if (docIds.isEmpty) return;

    // Fetch all docs in parallel
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final snapshots = await Future.wait(
      docIds.map((id) => measurementsCollection.doc(id).get(GetOptions(source: source))),
    );

    final batch = _baseRef.firestore.batch();

    for (var i = 0; i < docIds.length; i++) {
      final id = docIds[i];
      final docSnap = snapshots[i];
      final data = docSnap.data();
      if (data == null) continue;
      final historyRef = measurementHistoryCollection.doc();

      batch.set(historyRef, {
        'pondId': pondId,
        'measurementId': id,
        'parameter': data['parameter'],
        'action': 'delete',
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': user?.uid,
        'editorName': user?.displayName ?? 'Unknown',
        'before': {'value': data['value']},
        'after': null,
      });

      batch.delete(docSnap.reference);
    }
    await commitBatchWithTimeout(batch);
  }

  /// Updates growth sampling metrics in a single batch and logs them to history.
  Future<void> updateGrowthSampling({
    required String pondId,
    required User? user,
    required double? newAbw,
    required double? newAdg,
    required double? newDfr,
    required double? newFcr,
    required String? newNotes,
    required GrowthMetrics metrics,
  }) async {
    final allDocIds = [
      metrics.abwDocId,
      metrics.adgDocId,
      metrics.dfrDocId,
      metrics.fcrDocId,
    ].whereType<String>().toSet().toList();

    if (allDocIds.isEmpty) return;

    // Fetch all docs in parallel
    final source = isOffline() ? Source.cache : Source.serverAndCache;
    final snapshots = await Future.wait(
      allDocIds.map((id) => measurementsCollection.doc(id).get(GetOptions(source: source))),
    );

    final batch = _baseRef.firestore.batch();

    for (var i = 0; i < allDocIds.length; i++) {
      final id = allDocIds[i];
      final docSnap = snapshots[i];
      final data = docSnap.data();
      if (data == null) continue;

      final Map<String, dynamic> updates = {};
      final Map<String, dynamic> historyBefore = {};
      final Map<String, dynamic> historyAfter = {};

      double? newValue;
      if (id == metrics.abwDocId && newAbw != null && newAbw != metrics.abw) {
        newValue = newAbw;
      } else if (id == metrics.adgDocId && newAdg != null && newAdg != metrics.adg) {
        newValue = newAdg;
      } else if (id == metrics.dfrDocId && newDfr != null && newDfr != metrics.dfr) {
        newValue = newDfr;
      } else if (id == metrics.fcrDocId && newFcr != null && newFcr != metrics.fcr) {
        newValue = newFcr;
      }

      if (newValue != null) {
        updates['value'] = newValue;
        historyBefore['value'] = data['value'];
        historyAfter['value'] = newValue;
      }

      if (newNotes != metrics.notes) {
        final cleanNotes = (newNotes?.trim().isNotEmpty == true) ? newNotes!.trim() : null;
        updates['notes'] = cleanNotes;
        historyBefore['notes'] = data['notes'];
        historyAfter['notes'] = cleanNotes;
      }

      if (updates.isEmpty) continue;

      updates['editedAt'] = FieldValue.serverTimestamp();
      updates['editedBy'] = user?.uid;
      updates['editorName'] = user?.displayName;

      batch.update(docSnap.reference, updates);

      final historyRef = measurementHistoryCollection.doc();
      batch.set(historyRef, {
        'pondId': pondId,
        'measurementId': id,
        'parameter': data['parameter'],
        'action': 'update',
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': user?.uid,
        'editorName': user?.displayName ?? 'Unknown',
        'before': historyBefore,
        'after': historyAfter,
      });
    }

    await commitBatchWithTimeout(batch);
  }

}
