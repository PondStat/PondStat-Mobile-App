abstract class AppNotifier {
  Future<void> dispatchParameterAlert({
    required String pondId,
    required String pondName,
    required String parameter,
    required double value,
    required String unit,
    required String title,
    required String body,
    required String routePayload,
    required bool isCritical,
  });

  Future<void> dispatchWeatherAlert({
    required String pondId,
    required String pondName,
    required String title,
    required String body,
  });
}
