import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/services/safety/safety_evaluator.dart';
import 'package:pondstat/core/services/safety/alert_types.dart';

class PondHealthScore {
  final double score;
  final List<String> warningParameters;
  final List<String> criticalParameters;

  const PondHealthScore({
    required this.score,
    required this.warningParameters,
    required this.criticalParameters,
  });
}

class PondHealthParam {
  final String pondId;
  final String species;

  const PondHealthParam({
    required this.pondId,
    required this.species,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PondHealthParam &&
          runtimeType == other.runtimeType &&
          pondId == other.pondId &&
          species == other.species;

  @override
  int get hashCode => Object.hash(pondId, species);
}

final pondHealthScoreProvider =
    StreamProvider.family<PondHealthScore, PondHealthParam>((ref, param) {
  final repository = ref.watch(monitoringRepositoryProvider);
  final evaluator = SafetyEvaluator();

  return repository.measurementsCollection
      .where('pondId', isEqualTo: param.pondId)
      .orderBy('timestamp', descending: true)
      .limit(1000)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return const PondHealthScore(
        score: -1.0,
        warningParameters: [],
        criticalParameters: [],
      );
    }

    final Map<String, double> latestParamValues = {};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final parameterName = data['parameter'] as String?;
      final val = data['value'];
      if (parameterName == null || val == null) continue;

      // Since it's ordered by timestamp descending, the first occurrence
      // of any parameterName is the latest measurement.
      if (!latestParamValues.containsKey(parameterName)) {
        latestParamValues[parameterName] = (val as num).toDouble();
      }
    }

    final List<String> warningParams = [];
    final List<String> criticalParams = [];
    double totalPenalty = 0.0;

    for (final entry in latestParamValues.entries) {
      final String paramName = entry.key;
      final double val = entry.value;

      final parameter = MonitoringParameters.getParameterByLabel(paramName, param.species);
      if (parameter == null) {
        // Custom parameters (which won't have predefined bounds)
        // or unknown parameters are considered safe.
        continue;
      }

      final evaluation = evaluator.evaluate(parameter, val);
      if (evaluation != null) {
        if (evaluation.tier == AlertTier.critical) {
          totalPenalty += 30.0;
          criticalParams.add(paramName);
        } else if (evaluation.tier == AlertTier.warning) {
          totalPenalty += 10.0;
          warningParams.add(paramName);
        }
      }
    }

    final double finalScore = (100.0 - totalPenalty).clamp(0.0, 100.0);

    return PondHealthScore(
      score: finalScore,
      warningParameters: warningParams,
      criticalParameters: criticalParams,
    );
  });
});
