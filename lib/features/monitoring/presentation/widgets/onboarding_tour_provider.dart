import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/core/services/settings/settings_provider.dart';

class OnboardingTourState {
  final bool hasSeenOverview;
  final bool hasSeenTrends;
  final bool hasSeenOperations; // This serves as hasSeenSchedules
  final bool hasSeenFinances;
  final bool hasSeenGrowth;
  final bool hasSeenParameter;
  final bool hasSeenDashboard;
  final bool hasSeenCollaborators;

  OnboardingTourState({
    required this.hasSeenOverview,
    required this.hasSeenTrends,
    required this.hasSeenOperations,
    required this.hasSeenFinances,
    required this.hasSeenGrowth,
    required this.hasSeenParameter,
    required this.hasSeenDashboard,
    required this.hasSeenCollaborators,
  });

  OnboardingTourState copyWith({
    bool? hasSeenOverview,
    bool? hasSeenTrends,
    bool? hasSeenOperations,
    bool? hasSeenFinances,
    bool? hasSeenGrowth,
    bool? hasSeenParameter,
    bool? hasSeenDashboard,
    bool? hasSeenCollaborators,
  }) {
    return OnboardingTourState(
      hasSeenOverview: hasSeenOverview ?? this.hasSeenOverview,
      hasSeenTrends: hasSeenTrends ?? this.hasSeenTrends,
      hasSeenOperations: hasSeenOperations ?? this.hasSeenOperations,
      hasSeenFinances: hasSeenFinances ?? this.hasSeenFinances,
      hasSeenGrowth: hasSeenGrowth ?? this.hasSeenGrowth,
      hasSeenParameter: hasSeenParameter ?? this.hasSeenParameter,
      hasSeenDashboard: hasSeenDashboard ?? this.hasSeenDashboard,
      hasSeenCollaborators: hasSeenCollaborators ?? this.hasSeenCollaborators,
    );
  }
}

class OnboardingTourNotifier extends Notifier<OnboardingTourState> {
  static const _keyOverview = 'onboarding_seen_overview';
  static const _keyTrends = 'onboarding_seen_trends';
  static const _keyOperations = 'onboarding_seen_operations';
  static const _keyFinances = 'onboarding_seen_finances';
  static const _keyGrowth = 'onboarding_seen_growth';
  static const _keyParameter = 'onboarding_seen_parameter';
  static const _keyDashboard = 'onboarding_seen_dashboard';
  static const _keyCollaborators = 'onboarding_seen_collaborators';

  @override
  OnboardingTourState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return OnboardingTourState(
      hasSeenOverview: prefs.getBool(_keyOverview) ?? false,
      hasSeenTrends: prefs.getBool(_keyTrends) ?? false,
      hasSeenOperations: prefs.getBool(_keyOperations) ?? false,
      hasSeenFinances: prefs.getBool(_keyFinances) ?? false,
      hasSeenGrowth: prefs.getBool(_keyGrowth) ?? false,
      hasSeenParameter: prefs.getBool(_keyParameter) ?? false,
      hasSeenDashboard: prefs.getBool(_keyDashboard) ?? false,
      hasSeenCollaborators: prefs.getBool(_keyCollaborators) ?? false,
    );
  }

  Future<void> markOverviewAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyOverview, true);
    state = state.copyWith(hasSeenOverview: true);
  }

  Future<void> markTrendsAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyTrends, true);
    state = state.copyWith(hasSeenTrends: true);
  }

  Future<void> markOperationsAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyOperations, true);
    state = state.copyWith(hasSeenOperations: true);
  }

  Future<void> markFinancesAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyFinances, true);
    state = state.copyWith(hasSeenFinances: true);
  }

  Future<void> markGrowthAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyGrowth, true);
    state = state.copyWith(hasSeenGrowth: true);
  }

  Future<void> markParameterAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyParameter, true);
    state = state.copyWith(hasSeenParameter: true);
  }

  Future<void> markDashboardAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyDashboard, true);
    state = state.copyWith(hasSeenDashboard: true);
  }

  Future<void> markCollaboratorsAsSeen() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyCollaborators, true);
    state = state.copyWith(hasSeenCollaborators: true);
  }

  Future<void> resetAll() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_keyOverview);
    await prefs.remove(_keyTrends);
    await prefs.remove(_keyOperations);
    await prefs.remove(_keyFinances);
    await prefs.remove(_keyGrowth);
    await prefs.remove(_keyParameter);
    await prefs.remove(_keyDashboard);
    await prefs.remove(_keyCollaborators);
    state = OnboardingTourState(
      hasSeenOverview: false,
      hasSeenTrends: false,
      hasSeenOperations: false,
      hasSeenFinances: false,
      hasSeenGrowth: false,
      hasSeenParameter: false,
      hasSeenDashboard: false,
      hasSeenCollaborators: false,
    );
  }
}

final onboardingTourProvider =
    NotifierProvider<OnboardingTourNotifier, OnboardingTourState>(
  () => OnboardingTourNotifier(),
);

class TourTriggerNotifier extends Notifier<int?> {
  @override
  int? build() => null;

  @override
  set state(int? value) => super.state = value;
}

final tourTriggerProvider = NotifierProvider<TourTriggerNotifier, int?>(
  () => TourTriggerNotifier(),
);

