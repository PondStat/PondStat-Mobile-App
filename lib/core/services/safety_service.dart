import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/services/notification_service.dart';

class SafetyService {
  static final SafetyService _instance = SafetyService._internal();
  factory SafetyService() => _instance;
  SafetyService._internal();

  /// Checks if a [value] for a given [parameter] is within its defined safe range.
  /// If not, it triggers a notification alert.
  Future<void> checkAndNotify({
    required ParameterItem parameter,
    required double value,
    required String pondName,
  }) async {
    String? status;

    if (parameter.minVal != null && value < parameter.minVal!) {
      status = 'below';
    } else if (parameter.maxVal != null && value > parameter.maxVal!) {
      status = 'above';
    }

    if (status != null) {
      await NotificationService().showParameterAlert(
        pondName: pondName,
        parameter: parameter.label,
        value: value,
        unit: parameter.unit,
        minValue: parameter.minVal ?? 0,
        maxValue: parameter.maxVal ?? 0,
        status: status,
      );
    }
  }
}
