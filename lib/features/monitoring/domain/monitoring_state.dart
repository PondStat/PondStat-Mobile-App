import '../data/growth_repository.dart';

class MonitoringState {
  final bool isLoading;
  final String? error;
  final List<GrowthMetrics> metrics;

  const MonitoringState({
    this.isLoading = false,
    this.error,
    this.metrics = const [],
  });

  MonitoringState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    List<GrowthMetrics>? metrics,
  }) {
    return MonitoringState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      metrics: metrics ?? this.metrics,
    );
  }
}
