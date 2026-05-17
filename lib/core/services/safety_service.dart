import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/services/notification_service.dart';
import 'package:pondstat/core/services/safety/app_notifier.dart';
import 'package:pondstat/core/services/safety/alert_types.dart';
import 'package:pondstat/core/services/safety/safety_evaluator.dart';
import 'package:pondstat/core/services/safety/alert_formatter.dart';
import 'package:pondstat/core/services/safety/alert_rate_limiter.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return SafetyService(
    notifier: notificationService,
    evaluator: SafetyEvaluator(),
    formatter: AlertFormatter(),
    rateLimiter: AlertRateLimiter(),
  );
});

class SafetyService {
  final AppNotifier _notifier;
  final SafetyEvaluator _evaluator;
  final AlertFormatter _formatter;
  final AlertRateLimiter _rateLimiter;

  SafetyService({
    required AppNotifier notifier,
    required SafetyEvaluator evaluator,
    required AlertFormatter formatter,
    required AlertRateLimiter rateLimiter,
  })  : _notifier = notifier,
        _evaluator = evaluator,
        _formatter = formatter,
        _rateLimiter = rateLimiter;

  /// Checks if a [value] for a given [parameter] is within its defined safe range.
  /// If not, it triggers a notification alert, respecting cooldowns.
  Future<void> checkAndNotify({
    required ParameterItem parameter,
    required double value,
    required String pondId,
    required String pondName,
  }) async {
    final alert = getAlertPayload(
      parameter: parameter,
      value: value,
      pondId: pondId,
      pondName: pondName,
    );

    if (alert != null) {
      if (_rateLimiter.shouldAllowAlert(pondId, parameter.label, alert.tier)) {
        await _notifier.dispatchParameterAlert(
          pondId: pondId,
          pondName: pondName,
          parameter: parameter.label,
          value: value,
          unit: parameter.unit,
          title: alert.title,
          body: alert.body,
          routePayload: alert.routePayload,
          isCritical: alert.tier == AlertTier.critical,
        );
      }
    }
  }

  /// Evaluates the value and returns an alert payload if it's out of range.
  AlertPayload? getAlertPayload({
    required ParameterItem parameter,
    required double value,
    required String pondId,
    required String pondName,
  }) {
    final evaluation = _evaluator.evaluate(parameter, value);
    if (evaluation == null) return null;

    return _formatter.format(
      evaluation: evaluation,
      parameter: parameter,
      value: value,
      pondId: pondId,
      pondName: pondName,
    );
  }
}
