import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_helper.dart';

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
  static Future<List<GrowthMetrics>> calculateGrowthMetrics(String pondId) async {
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

    final stockSamplingDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'weekly' && data['parameter'] == 'Stock sampling';
    }).toList();

    final feedingDocs = allDocs.where((doc) {
      final data = doc.data();
      return data['type'] == 'daily' && data['parameter'] == 'Feeding';
    }).toList();

    if (stockSamplingDocs.isEmpty) return [];

    final List<GrowthMetrics> metrics = [];

    for (int i = 0; i < stockSamplingDocs.length; i++) {
      final currentData = stockSamplingDocs[i].data();

      final Timestamp currentTimestamp = currentData['timestamp'] as Timestamp;
      final DateTime currentDate = currentTimestamp.toDate();
      final double currentAbw = (currentData['value'] as num?)?.toDouble() ?? 0.0;

      double adg = 0.0;
      double fcr = 0.0;
      double dfr = 0.0;

      if (i > 0) {
        final previousData = stockSamplingDocs[i - 1].data();
        final Timestamp previousTimestamp = previousData['timestamp'] as Timestamp;
        final DateTime previousDate = previousTimestamp.toDate();
        final double previousAbw =
            (previousData['value'] as num?)?.toDouble() ?? 0.0;

        final int daysBetween = currentDate.difference(previousDate).inDays;

        if (daysBetween > 0) {
          adg = (currentAbw - previousAbw) / daysBetween;

          final intervalFeedDocs = feedingDocs.where((doc) {
            final data = doc.data();
            final Timestamp ts = data['timestamp'] as Timestamp;
            final DateTime date = ts.toDate();
            return !date.isBefore(previousDate) && !date.isAfter(currentDate);
          }).toList();

          final double totalFeedKg = intervalFeedDocs.fold(0.0, (sum, doc) {
            final value = (doc.data()['value'] as num?)?.toDouble() ?? 0.0;
            return sum + value;
          });

          final double averageDailyFeedKg = totalFeedKg / daysBetween;

          final double previousBiomassKg = (previousAbw * fishCount) / 1000.0;
          final double currentBiomassKg = (currentAbw * fishCount) / 1000.0;
          final double biomassGainKg = currentBiomassKg - previousBiomassKg;

          if (currentBiomassKg > 0) {
            dfr = (averageDailyFeedKg / currentBiomassKg) * 100.0;
          }

          if (biomassGainKg > 0) {
            fcr = totalFeedKg / biomassGainKg;
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