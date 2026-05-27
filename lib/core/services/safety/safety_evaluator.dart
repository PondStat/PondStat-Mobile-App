import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'alert_types.dart';

class SafetyEvaluation {
  final AlertTier tier;
  final AlertDirection direction;

  const SafetyEvaluation({required this.tier, required this.direction});
}

class SafetyEvaluator {
  /// Evaluates a parameter value against its absolute and optimal thresholds.
  /// Returns null if the value is within optimal bounds.
  SafetyEvaluation? evaluate(ParameterItem parameter, double value) {
    if (value.isNaN || value.isInfinite) {
      return const SafetyEvaluation(
        tier: AlertTier.critical,
        direction: AlertDirection.above,
      );
    }

    // 1. Check Critical Bounds first
    if (parameter.absoluteMin != null && value < parameter.absoluteMin!) {
      return const SafetyEvaluation(
        tier: AlertTier.critical,
        direction: AlertDirection.below,
      );
    }
    if (parameter.absoluteMax != null && value > parameter.absoluteMax!) {
      return const SafetyEvaluation(
        tier: AlertTier.critical,
        direction: AlertDirection.above,
      );
    }

    // 2. Check Warning Bounds
    if (parameter.optimalMin != null && value < parameter.optimalMin!) {
      return const SafetyEvaluation(
        tier: AlertTier.warning,
        direction: AlertDirection.below,
      );
    }
    if (parameter.optimalMax != null && value > parameter.optimalMax!) {
      return const SafetyEvaluation(
        tier: AlertTier.warning,
        direction: AlertDirection.above,
      );
    }

    // Safe
    return null;
  }
}
