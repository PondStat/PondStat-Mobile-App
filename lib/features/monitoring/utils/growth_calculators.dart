class GrowthCalculators {
  GrowthCalculators._();

  /// Calculates Average Body Weight (ABW) in grams.
  /// Formula: Total weight of sampled fish / Number of fish sampled.
  static double? calculateABW({required double? weight, required double? count}) {
    if (weight != null && count != null && weight > 0 && count > 0) {
      return weight / count;
    }
    return null;
  }

  /// Calculates Average Daily Gain (ADG) in grams/day.
  /// Formula: (Current ABW - Previous ABW) / Days between samples.
  static double? calculateADG({
    required double? currentAbw,
    required double? previousAbw,
    required double? days,
  }) {
    if (currentAbw != null &&
        previousAbw != null &&
        days != null &&
        currentAbw > 0 &&
        previousAbw > 0 &&
        days > 0) {
      return (currentAbw - previousAbw) / days;
    }
    return null;
  }

  /// Calculates Daily Feed Rate (DFR) in kg/day.
  /// Formula: (Stocked Quantity * (Survival Rate / 100) * ABW * (Feeding Rate / 100)) / 1000.
  static double? calculateDFR({
    required double? stocked,
    required double? survivalRate,
    required double? abw,
    required double? feedingRate,
  }) {
    if (stocked != null &&
        survivalRate != null &&
        abw != null &&
        feedingRate != null &&
        stocked > 0 &&
        survivalRate >= 0 &&
        survivalRate <= 100 &&
        abw > 0 &&
        feedingRate >= 0 &&
        feedingRate <= 100) {
      return (stocked * (survivalRate / 100.0) * abw * (feedingRate / 100.0)) / 1000.0;
    }
    return null;
  }

  /// Calculates Feed Conversion Ratio (FCR).
  /// Formula: Total feed given / Total weight gained.
  static double? calculateFCR({required double? feedGiven, required double? weightGained}) {
    if (feedGiven != null && weightGained != null && feedGiven > 0 && weightGained > 0) {
      return feedGiven / weightGained;
    }
    return null;
  }

  /// Calculates the average for bacterial replicates.
  static double calculateBacterialAverage(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculates the Colony Forming Units (CFU) for bacterial analysis.
  static double calculateBacterialCfu(double average, double dilutionFactor) {
    return average * dilutionFactor;
  }
}
