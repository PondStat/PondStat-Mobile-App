import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'alert_types.dart';
import 'safety_evaluator.dart';

class AlertFormatter {
  AlertPayload format({
    required SafetyEvaluation evaluation,
    required ParameterItem parameter,
    required double value,
    required String pondId,
    required String pondName,
  }) {
    final emoji = evaluation.tier == AlertTier.critical ? '🚨' : '⚠️';
    final tierString = evaluation.tier == AlertTier.critical ? 'CRITICAL' : 'Warning';
    final directionString = evaluation.direction == AlertDirection.below ? 'low' : 'high';

    final title = '$emoji $tierString: ${parameter.label} - $pondName';
    
    // Construct the safe range string without magic defaults.
    String boundsStr = '';
    if (evaluation.tier == AlertTier.critical) {
      if (parameter.absoluteMin != null && parameter.absoluteMax != null) {
        boundsStr = 'Safe range: ${parameter.absoluteMin} - ${parameter.absoluteMax} ${parameter.unit}';
      } else if (parameter.absoluteMin != null) {
        boundsStr = 'Must be above ${parameter.absoluteMin} ${parameter.unit}';
      } else if (parameter.absoluteMax != null) {
        boundsStr = 'Must be below ${parameter.absoluteMax} ${parameter.unit}';
      }
    } else {
      if (parameter.optimalMin != null && parameter.optimalMax != null) {
        boundsStr = 'Optimal range: ${parameter.optimalMin} - ${parameter.optimalMax} ${parameter.unit}';
      } else if (parameter.optimalMin != null) {
        boundsStr = 'Should be above ${parameter.optimalMin} ${parameter.unit}';
      } else if (parameter.optimalMax != null) {
        boundsStr = 'Should be below ${parameter.optimalMax} ${parameter.unit}';
      }
    }

    final body = '${parameter.label} is $directionString: $value ${parameter.unit}\n$boundsStr';
    
    // Actionable routing payload
    // Example: /monitoring?pondId=123&parameter=pH
    final routePayload = '/monitoring?pondId=$pondId&parameter=${parameter.label}';

    return (
      title: title,
      body: body,
      tier: evaluation.tier,
      routePayload: routePayload,
    );
  }
}
