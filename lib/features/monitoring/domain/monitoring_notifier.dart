import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'monitoring_state.dart';
import '../data/growth_repository.dart';

class MonitoringNotifier extends Notifier<MonitoringState> {
  @override
  MonitoringState build() {
    return const MonitoringState();
  }

  Future<void> fetchGrowthMetrics(String pondId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final metrics = await GrowthRepository.calculateGrowthMetrics(pondId);
      state = state.copyWith(isLoading: false, metrics: metrics);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final monitoringNotifierProvider =
    NotifierProvider<MonitoringNotifier, MonitoringState>(() {
      return MonitoringNotifier();
    });
