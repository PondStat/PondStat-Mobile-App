import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class GrowthMetrics {
  final DateTime date;
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
  static Future<bool> hasRecordedSamplingThisWeek(String pondId) async {
    final now = DateTime.now();
    // A weekly limit means they cannot record again if a record exists within the last 6 days.
    final sixDaysAgo = now.subtract(const Duration(days: 6));

    final measurementsSnapshot = await FirestoreHelper.measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .where('type', isEqualTo: 'weekly')
        .where('parameter', isEqualTo: 'Total weight of sampled fish')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sixDaysAgo))
        .get();

    return measurementsSnapshot.docs.isNotEmpty;
  }

  static Future<List<GrowthMetrics>> calculateGrowthMetrics(
    String pondId,
  ) async {
    final pondDoc = await FirestoreHelper.pondsCollection.doc(pondId).get();
    if (!pondDoc.exists) return [];

    final pondData = pondDoc.data() ?? {};
    final int fishCount = (pondData['stockingQuantity'] as num?)?.toInt() ?? 0;
    if (fishCount <= 0) return [];

    final measurementsSnapshot = await FirestoreHelper.measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .get();

    final allDocs = measurementsSnapshot.docs.toList()
      ..sort((a, b) {
        final tA = a.data()['timestamp'] as Timestamp?;
        final tB = b.data()['timestamp'] as Timestamp?;
        if (tA == null || tB == null) return 0;
        return tA.compareTo(tB);
      });

    final weightDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'weekly' &&
          data['parameter'] == 'Total weight of sampled fish';
    }).toList();

    final countDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'weekly' &&
          data['parameter'] == 'Number of fish sampled';
    }).toList();

    final feedingRateDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'daily' && data['parameter'] == 'Feeding rate';
    }).toList();

    final feedConsumedDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'daily' &&
          data['parameter'] == 'Total feed consumed';
    }).toList();

    final weightGainedDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'daily' &&
          data['parameter'] == 'Total weight gained';
    }).toList();

    if (weightDocs.isEmpty || countDocs.isEmpty) return [];

    // Pair weights and counts by date
    final Map<String, double> dailyWeights = {};
    final Map<String, String> dailyWeightIds = {};
    final Map<String, String> dailyRecorderNames = {};
    final Map<String, String?> dailyEditorNames = {};
    final Map<String, double> dailyCounts = {};
    final Map<String, String> dailyCountIds = {};
    final Set<String> allDates = {};

    for (var doc in weightDocs) {
      final data = doc.data();
      if (data['timestamp'] == null || data['value'] == null) continue;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateKey = "${date.year}-${date.month}-${date.day}";
      dailyWeights[dateKey] = (data['value'] as num).toDouble();
      dailyWeightIds[dateKey] = doc.id;
      dailyRecorderNames[dateKey] = data['recorderName'] as String? ?? 'Unknown';
      dailyEditorNames[dateKey] = data['editorName'] as String?;
      allDates.add(dateKey);
    }

    for (var doc in countDocs) {
      final data = doc.data();
      if (data['timestamp'] == null || data['value'] == null) continue;
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateKey = "${date.year}-${date.month}-${date.day}";
      dailyCounts[dateKey] = (data['value'] as num).toDouble();
      dailyCountIds[dateKey] = doc.id;
      if (!dailyRecorderNames.containsKey(dateKey)) {
          dailyRecorderNames[dateKey] = data['recorderName'] as String? ?? 'Unknown';
      }
      if (!dailyEditorNames.containsKey(dateKey) || dailyEditorNames[dateKey] == null) {
          dailyEditorNames[dateKey] = data['editorName'] as String?;
      }
      allDates.add(dateKey);
    }

    final List<Map<String, dynamic>> pairedSamplings = [];
    for (var dateKey in allDates) {
      if (dailyWeights.containsKey(dateKey) &&
          dailyCounts.containsKey(dateKey)) {
        final weight = dailyWeights[dateKey]!;
        final count = dailyCounts[dateKey]!;
        if (count > 0) {
          final parts = dateKey.split('-');
          final date = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
          pairedSamplings.add({
            'date': date,
            'abw': weight / count,
            'totalWeight': weight,
            'sampleCount': count,
            'weightDocId': dailyWeightIds[dateKey],
            'countDocId': dailyCountIds[dateKey],
            'recorderName': dailyRecorderNames[dateKey],
            'editorName': dailyEditorNames[dateKey],
          });
        }
      }
    }

    pairedSamplings.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    if (pairedSamplings.isEmpty) return [];

    final List<GrowthMetrics> metrics = [];

    for (int i = 0; i < pairedSamplings.length; i++) {
      final currentSampling = pairedSamplings[i];
      final DateTime currentDate = currentSampling['date'] as DateTime;
      final double currentAbw = currentSampling['abw'] as double;

      double adg = 0.0;
      double fcr = 0.0;
      double dfr = 0.0;
      double feedingRate = 0.0;
      double feedConsumed = 0.0;
      double weightGained = 0.0;

      if (i > 0) {
        final previousSampling = pairedSamplings[i - 1];
        final DateTime previousDate = previousSampling['date'] as DateTime;
        final double previousAbw = previousSampling['abw'] as double;

        final int daysBetween = currentDate.difference(previousDate).inDays;

        if (daysBetween > 0) {
          adg = (currentAbw - previousAbw) / daysBetween;

          // Get the feeding rate for the CURRENT sampling date for DFR
          final currentFeedingRateDoc = feedingRateDocs.where((doc) {
            final data = doc.data();
            if (data['timestamp'] == null) return false;
            final date = (data['timestamp'] as Timestamp).toDate();
            return date.year == currentDate.year &&
                date.month == currentDate.month &&
                date.day == currentDate.day;
          }).toList();

          if (currentFeedingRateDoc.isNotEmpty) {
            final data = currentFeedingRateDoc.first.data();
            if (data['value'] != null) {
              feedingRate = (data['value'] as num).toDouble();
              dfr = currentAbw * fishCount * feedingRate / 100.0;
            }
          }

          // Calculate total feed and weight gained between samplings for FCR
          final start = DateTime(
            previousDate.year,
            previousDate.month,
            previousDate.day,
          );
          final end = DateTime(
            currentDate.year,
            currentDate.month,
            currentDate.day,
          );

          final periodFeedDocs = feedConsumedDocs.where((doc) {
            final data = doc.data();
            if (data['timestamp'] == null) return false;
            final date = (data['timestamp'] as Timestamp).toDate();
            final d = DateTime(date.year, date.month, date.day);
            return !d.isBefore(start) && !d.isAfter(end);
          }).toList();

          final periodWeightGainedDocs = weightGainedDocs.where((doc) {
            final data = doc.data();
            if (data['timestamp'] == null) return false;
            final date = (data['timestamp'] as Timestamp).toDate();
            final d = DateTime(date.year, date.month, date.day);
            return !d.isBefore(start) && !d.isAfter(end);
          }).toList();

          final double totalFeed = periodFeedDocs.fold(
            0.0,
            (acc, doc) {
              final val = doc.data()['value'];
              return acc + (val != null ? (val as num).toDouble() : 0.0);
            },
          );
          final double totalWeightGained = periodWeightGainedDocs.fold(
            0.0,
            (acc, doc) {
              final val = doc.data()['value'];
              return acc + (val != null ? (val as num).toDouble() : 0.0);
            },
          );

          feedConsumed = totalFeed;
          weightGained = totalWeightGained;

          if (totalWeightGained > 0) {
            fcr = totalFeed / totalWeightGained;
          }
        }
      }

      metrics.add(
        GrowthMetrics(
          date: currentDate,
          abw: _round(currentAbw, 1),
          adg: _round(adg, 2),
          fcr: _round(fcr, 2),
          dfr: _round(dfr, 2),
          totalWeight: _round(currentSampling['totalWeight'] as double, 1),
          sampleCount: _round(currentSampling['sampleCount'] as double, 0),
          feedingRate: _round(feedingRate, 2),
          feedConsumed: _round(feedConsumed, 2),
          weightGained: _round(weightGained, 2),
          weightDocId: currentSampling['weightDocId'] as String?,
          countDocId: currentSampling['countDocId'] as String?,
          recorderName: currentSampling['recorderName'] as String?,
          editorName: currentSampling['editorName'] as String?,
        ),
      );
    }

    return metrics.reversed.toList();
  }

  static double _round(double value, int places) {
    return double.parse(value.toStringAsFixed(places));
  }
}
