import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/services/notification_service.dart';

final safetyServiceProvider = Provider<SafetyService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return SafetyService(notificationService);
});

class SafetyService {
  final NotificationService _notificationService;

  SafetyService(this._notificationService);

  /// Checks if a [value] for a given [parameter] is within its defined safe range.
  /// If not, it triggers a notification alert.
  Future<void> checkAndNotify({
    required ParameterItem parameter,
    required double value,
    required String pondName,
  }) async {
    final alert = getAlertPayload(
      parameter: parameter,
      value: value,
      pondName: pondName,
    );

    if (alert != null) {
      await _notificationService.showParameterAlert(
        pondName: pondName,
        parameter: parameter.label,
        value: value,
        unit: parameter.unit,
        minValue: parameter.absoluteMin ?? 0,
        maxValue: parameter.absoluteMax ?? 0,
        status: value < (parameter.absoluteMin ?? 0) ? 'below' : 'above',
      );
    }
  }

  /// Evaluates the value and returns an alert payload if it's out of range.
  Map<String, dynamic>? getAlertPayload({
    required ParameterItem parameter,
    required double value,
    required String pondName,
  }) {
    String? status;

    if (parameter.absoluteMin != null && value < parameter.absoluteMin!) {
      status = 'below';
    } else if (parameter.absoluteMax != null &&
        value > parameter.absoluteMax!) {
      status = 'above';
    }

    if (status != null) {
      final String title = '⚠️ ${parameter.label} Alert - $pondName';
      final String body = status == 'below'
          ? '${parameter.label} is LOW: $value ${parameter.unit}\nSafe range: ${parameter.absoluteMin ?? 0} - ${parameter.absoluteMax ?? 0} ${parameter.unit}'
          : '${parameter.label} is HIGH: $value ${parameter.unit}\nSafe range: ${parameter.absoluteMin ?? 0} - ${parameter.absoluteMax ?? 0} ${parameter.unit}';

      return {'title': title, 'body': body};
    }
    return null;
  }
}
