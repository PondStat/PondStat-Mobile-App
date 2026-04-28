import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class TrendDataPoint {
  final DateTime timestamp;
  final double value;

  TrendDataPoint(this.timestamp, this.value);
}

class NormalizedTrendPoint {
  final DateTime timestamp;
  final double actualValue;
  final double normalizedValue;
  final String parameterName;

  NormalizedTrendPoint({
    required this.timestamp,
    required this.actualValue,
    required this.normalizedValue,
    required this.parameterName,
  });
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
  static Map<String, List<NormalizedTrendPoint>> getNormalizedParameters(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String species,
    List<String> targetParams,
  ) {
    final Map<String, List<TrendDataPoint>> rawData = {};

    for (var doc in docs) {
      final data = doc.data();
      final parameter = data['parameter'] as String?;
      if (parameter == null || !targetParams.contains(parameter)) continue;

      final value = (data['value'] as num?)?.toDouble();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      if (value != null && timestamp != null) {
        rawData.putIfAbsent(parameter, () => []).add(TrendDataPoint(timestamp, value));
      }
    }

    final Map<String, List<NormalizedTrendPoint>> normalizedData = {};

    rawData.forEach((parameter, points) {
      if (points.isEmpty) return;

      points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      final paramItem = MonitoringParameters.getParameterByLabel(parameter, species);
      
      // Determine min/max for normalization
      double min = paramItem?.minVal ?? points.map((p) => p.value).reduce((a, b) => a < b ? a : b);
      double max = paramItem?.maxVal ?? points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
      
      // Ensure min != max to avoid division by zero
      if (min == max) {
        min -= 1;
        max += 1;
      }

      final normalizedPoints = points.map((p) {
        double normVal = ((p.value - min) / (max - min)) * 100;
        // Clamp between 0 and 100 just in case values exceed bounds
        normVal = normVal.clamp(0.0, 100.0);
        return NormalizedTrendPoint(
          timestamp: p.timestamp,
          actualValue: p.value,
          normalizedValue: normVal,
          parameterName: parameter,
        );
      }).toList();

      normalizedData[parameter] = normalizedPoints;
    });

    return normalizedData;
  }

  static List<ParameterStats> processMeasurements(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String species,
  ) {
    final Map<String, List<TrendDataPoint>> groupedData = {};

    final excludedParams = [
      'Feeding rate',
      'Total feed consumed',
      'Total weight gained',
      'Total weight of fish sampled',
      'Number of fish sampled',
    ];

    for (var doc in docs) {
      final data = doc.data();
      final parameter = data['parameter'] as String?;
      
      if (parameter == null || excludedParams.contains(parameter)) continue;

      final value = (data['value'] as num?)?.toDouble();
      final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

      if (value != null && timestamp != null) {
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
