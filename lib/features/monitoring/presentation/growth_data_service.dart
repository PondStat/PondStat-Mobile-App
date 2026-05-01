import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class GrowthMetrics {
  final DateTime date;
  final int weekNumber;
  final double abw;
  final double adg;
  final double fcr;
  final double dfr;
  final double totalWeight;
  final double sampleCount;
  final double feedingRate;
  final double feedConsumed;
  final double weightGained;
  final String? weightDocId;
  final String? countDocId;
  final String? recorderName;
  final String? editorName;

  GrowthMetrics({
    required this.date,
    required this.weekNumber,
    required this.abw,
    this.adg = 0.0,
    this.fcr = 0.0,
    this.dfr = 0.0,
    this.totalWeight = 0.0,
    this.sampleCount = 0.0,
    this.feedingRate = 0.0,
    this.feedConsumed = 0.0,
    this.weightGained = 0.0,
    this.weightDocId,
    this.countDocId,
    this.recorderName,
    this.editorName,
  });
}

class GrowthDataService {
  static Future<List<GrowthMetrics>> calculateGrowthMetrics(
    String pondId,
  ) async {
    final pondDoc = await FirestoreHelper.pondsCollection.doc(pondId).get();
    if (!pondDoc.exists) return [];

    final pondData = pondDoc.data() ?? {};
    final int fishCount = (pondData['stockingQuantity'] as num?)?.toInt() ?? 0;

    final measurementsSnapshot = await FirestoreHelper.measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .get();

    final relevantParams = [
      'Total weight of sampled fish',
      'Number of fish sampled',
      'Feeding rate',
      'Total feed consumed',
      'Total weight gained',
    ];

    final allDocs =
        measurementsSnapshot.docs
            .where((doc) => relevantParams.contains(doc.data()['parameter']))
            .toList()
          ..sort((a, b) {
            final tA = a.data()['timestamp'] as Timestamp?;
            final tB = b.data()['timestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tA.compareTo(tB);
          });

    if (allDocs.isEmpty) return [];

    DateTime pondStartDate;
    if (pondData['createdAt'] != null) {
      pondStartDate = (pondData['createdAt'] as Timestamp).toDate();
    } else {
      pondStartDate = (allDocs.first.data()['timestamp'] as Timestamp).toDate();
    }

    final Map<int, Map<String, dynamic>> weeklyBuckets = {};

    for (var doc in allDocs) {
      final data = doc.data();
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
          'Total weight of sampled fish': 0.0,
          'Number of fish sampled': 0.0,
          'Feeding rate': 0.0,
          'Total feed consumed': 0.0,
          'Total weight gained': 0.0,
        },
      );

      // Keep the latest date for this week's card
      weeklyBuckets[displayWeek]!['date'] = date;

      // Add value to the bucket (sums if recorded multiple times, typically just once)
      weeklyBuckets[displayWeek]![param] =
          (weeklyBuckets[displayWeek]![param] as double) + val;

      if (param == 'Total weight of sampled fish') {
        weeklyBuckets[displayWeek]!['weightDocId'] = doc.id;
      } else if (param == 'Number of fish sampled') {
        weeklyBuckets[displayWeek]!['countDocId'] = doc.id;
      }

      weeklyBuckets[displayWeek]!['recorderName'] =
          data['recorderName'] as String? ??
          weeklyBuckets[displayWeek]!['recorderName'] ??
          'Unknown';
      if (data['editorName'] != null) {
        weeklyBuckets[displayWeek]!['editorName'] = data['editorName'];
      }
    }

    final sortedWeeks = weeklyBuckets.keys.toList()..sort();
    final List<GrowthMetrics> metrics = [];

    for (int i = 0; i < sortedWeeks.length; i++) {
      final week = sortedWeeks[i];
      final bucket = weeklyBuckets[week]!;

      final double totalWeight = bucket['Total weight of sampled fish'];
      final double sampleCount = bucket['Number of fish sampled'];
      final double feedingRate = bucket['Feeding rate'];
      final double feedConsumed = bucket['Total feed consumed'];
      final double weightGained = bucket['Total weight gained'];

      final double currentAbw = sampleCount > 0
          ? totalWeight / sampleCount
          : 0.0;

      double adg = 0.0;
      double dfr = currentAbw * fishCount * feedingRate / 100.0;
      double fcr = weightGained > 0 ? feedConsumed / weightGained : 0.0;

      if (i > 0) {
        final prevWeek = sortedWeeks[i - 1];
        final prevBucket = weeklyBuckets[prevWeek]!;

        final prevTotalWeight =
            prevBucket['Total weight of sampled fish'] as double;
        final prevSampleCount = prevBucket['Number of fish sampled'] as double;
        final prevAbw = prevSampleCount > 0
            ? prevTotalWeight / prevSampleCount
            : 0.0;

        final DateTime currentDate = bucket['date'] as DateTime;
        final DateTime prevDate = prevBucket['date'] as DateTime;
        final int daysBetween = currentDate.difference(prevDate).inDays;

        if (daysBetween > 0 && currentAbw > 0 && prevAbw > 0) {
          adg = (currentAbw - prevAbw) / daysBetween;
        }
      }

      metrics.add(
        GrowthMetrics(
          date: bucket['date'] as DateTime,
          weekNumber: week,
          abw: _round(currentAbw, 1),
          adg: _round(adg, 2),
          fcr: _round(fcr, 2),
          dfr: _round(dfr, 2),
          totalWeight: _round(totalWeight, 1),
          sampleCount: _round(sampleCount, 0),
          feedingRate: _round(feedingRate, 2),
          feedConsumed: _round(feedConsumed, 2),
          weightGained: _round(weightGained, 2),
          weightDocId: bucket['weightDocId'] as String?,
          countDocId: bucket['countDocId'] as String?,
          recorderName: bucket['recorderName'] as String?,
          editorName: bucket['editorName'] as String?,
        ),
      );
    }

    return metrics.reversed.toList();
  }

  static double _round(double value, int places) {
    return double.parse(value.toStringAsFixed(places));
  }
}
