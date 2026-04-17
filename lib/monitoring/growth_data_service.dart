class GrowthMetrics {
  final DateTime date;
  final double abw;
  final double adg;
  final double fcr;
  final double dfr;

  GrowthMetrics({
    required this.date,
    required this.abw,
    this.adg = 0.0,
    this.fcr = 0.0,
    this.dfr = 0.0,
  });
}

class GrowthDataService {
  static Future<List<GrowthMetrics>> calculateGrowthMetrics(String pondId) async {
    // Returning dummy data for UI/UX showcase as requested
    final now = DateTime.now();
    return [
      GrowthMetrics(
        date: now,
        abw: 25.5,
        adg: 0.45,
        fcr: 1.2,
        dfr: 2.5,
      ),
      GrowthMetrics(
        date: now.subtract(const Duration(days: 7)),
        abw: 22.3,
        adg: 0.42,
        fcr: 1.15,
        dfr: 2.6,
      ),
      GrowthMetrics(
        date: now.subtract(const Duration(days: 14)),
        abw: 19.4,
        adg: 0.40,
        fcr: 1.1,
        dfr: 2.8,
      ),
      GrowthMetrics(
        date: now.subtract(const Duration(days: 21)),
        abw: 16.6,
        adg: 0.38,
        fcr: 1.05,
        dfr: 3.0,
      ),
      GrowthMetrics(
        date: now.subtract(const Duration(days: 28)),
        abw: 14.0,
        adg: 0.35,
        fcr: 1.0,
        dfr: 3.2,
      ),
    ];
  }
}
