import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class GrowthMetrics {
  final DateTime date;
  final double abw;
  final double adg;
  final double fcr;
  final double dfr;

  GrowthMetrics({
    required this.date,
    required this.abw,
    this.adg = 0.0,
    this.fcr = 0.0,
    this.dfr = 0.0,
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
    if (fishCount <= 0) return [];

    final measurementsSnapshot = await FirestoreHelper.measurementsCollection
        .where('pondId', isEqualTo: pondId)
        .orderBy('timestamp', descending: false)
        .get();

    final allDocs = measurementsSnapshot.docs;

    final weightDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'weekly' &&
          data['parameter'] == 'Total weight of fish sampled';
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
    final Map<String, double> dailyCounts = {};
    final Set<String> allDates = {};

    for (var doc in weightDocs) {
      final data = doc.data();
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateKey = "${date.year}-${date.month}-${date.day}";
      dailyWeights[dateKey] = (data['value'] as num).toDouble();
      allDates.add(dateKey);
    }

    for (var doc in countDocs) {
      final data = doc.data();
      final date = (data['timestamp'] as Timestamp).toDate();
      final dateKey = "${date.year}-${date.month}-${date.day}";
      dailyCounts[dateKey] = (data['value'] as num).toDouble();
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
          pairedSamplings.add({'date': date, 'abw': weight / count});
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

      if (i > 0) {
        final previousSampling = pairedSamplings[i - 1];
        final DateTime previousDate = previousSampling['date'] as DateTime;
        final double previousAbw = previousSampling['abw'] as double;

        final int daysBetween = currentDate.difference(previousDate).inDays;

        if (daysBetween > 0) {
          adg = (currentAbw - previousAbw) / daysBetween;

          // Get the feeding rate for the CURRENT sampling date for DFR
          final currentFeedingRateDoc = feedingRateDocs.where((doc) {
            final date = (doc.data()['timestamp'] as Timestamp).toDate();
            return date.year == currentDate.year &&
                date.month == currentDate.month &&
                date.day == currentDate.day;
          }).toList();

          if (currentFeedingRateDoc.isNotEmpty) {
            final feedingRate =
                (currentFeedingRateDoc.first.data()['value'] as num).toDouble();
            dfr = currentAbw * fishCount * feedingRate / 100.0;
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
            final date = (doc.data()['timestamp'] as Timestamp).toDate();
            final d = DateTime(date.year, date.month, date.day);
            return !d.isBefore(start) && !d.isAfter(end);
          }).toList();

          final periodWeightGainedDocs = weightGainedDocs.where((doc) {
            final date = (doc.data()['timestamp'] as Timestamp).toDate();
            final d = DateTime(date.year, date.month, date.day);
            return !d.isBefore(start) && !d.isAfter(end);
          }).toList();

          final double totalFeed = periodFeedDocs.fold(
            0.0,
            (acc, doc) => acc + (doc.data()['value'] as num).toDouble(),
          );
          final double totalWeightGained = periodWeightGainedDocs.fold(
            0.0,
            (acc, doc) => acc + (doc.data()['value'] as num).toDouble(),
          );

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
        ),
      );
    }

    return metrics.reversed.toList();
  }

  static double _round(double value, int places) {
    return double.parse(value.toStringAsFixed(places));
  }
}
