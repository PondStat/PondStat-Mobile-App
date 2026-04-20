import 'package:cloud_firestore/cloud_firestore.dart';
import 'monitoring_parameters.dart';

class TrendDataPoint {
  final DateTime timestamp;
  final double value;

  TrendDataPoint(this.timestamp, this.value);
}

class ParameterStats {
  final String parameter;
  final List<TrendDataPoint> dataPoints;
  final double average;
  final double min;
  final double max;
  final int outlierCount;

  ParameterStats({
    required this.parameter,
    required this.dataPoints,
    required this.average,
    required this.min,
    required this.max,
    required this.outlierCount,
  });
}

class TrendsDataService {
  static List<ParameterStats> processMeasurements(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String species,
  ) {
    final Map<String, List<TrendDataPoint>> groupedData = {};

    for (var doc in docs) {
      final data = doc.data();
      final parameter = data['parameter'] as String?;
      final value = (data['value'] as num?)?.toDouble();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      if (parameter != null && value != null && timestamp != null) {
        groupedData
            .putIfAbsent(parameter, () => [])
            .add(TrendDataPoint(timestamp, value));
      }
    }

    final List<ParameterStats> statsList = [];

    groupedData.forEach((parameter, points) {
      if (points.isEmpty) return;

      // Sort points by timestamp just in case
      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final values = points.map((p) => p.value).toList();
      final average = values.reduce((a, b) => a + b) / values.length;
      final min = values.reduce((a, b) => a < b ? a : b);
      final max = values.reduce((a, b) => a > b ? a : b);

      // Outlier detection based on MonitoringParameters
      final paramItem = MonitoringParameters.getParameterByLabel(
        parameter,
        species,
      );
      int outliers = 0;
      if (paramItem != null) {
        for (var val in values) {
          if ((paramItem.minVal != null && val < paramItem.minVal!) ||
              (paramItem.maxVal != null && val > paramItem.maxVal!)) {
            outliers++;
          }
        }
      }

      statsList.add(
        ParameterStats(
          parameter: parameter,
          dataPoints: points,
          average: double.parse(average.toStringAsFixed(2)),
          min: min,
          max: max,
          outlierCount: outliers,
        ),
      );
    });

    return statsList;
  }
}
