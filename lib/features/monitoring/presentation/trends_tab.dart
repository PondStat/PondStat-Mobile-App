import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';
import 'package:pondstat/features/monitoring/presentation/trends_data_service.dart';
import 'package:pondstat/features/monitoring/presentation/growth_data_service.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/physical_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/chemical_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/biological_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/fish_gains_chart.dart';

class TrendsTab extends StatefulWidget {
  final String pondId;
  final String species;
  final String userRole;
  final DateTime startDate;
  final DateTime endDate;

  const TrendsTab({
    super.key,
    required this.pondId,
    required this.species,
    required this.userRole,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  late Stream<QuerySnapshot<Map<String, dynamic>>>
  _historicalMeasurementsStream;
  Future<List<GrowthMetrics>>? _growthMetricsFuture;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void didUpdateWidget(covariant TrendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _initData();
    }
  }

  void _initData() {
    _historicalMeasurementsStream = FirestoreHelper.getMeasurementsByDateRange(
      widget.pondId,
      widget.startDate,
      widget.endDate,
    ).snapshots();

    _growthMetricsFuture =
        GrowthDataService.calculateGrowthMetrics(widget.pondId).then((metrics) {
          final endOfDay = DateTime(
            widget.endDate.year,
            widget.endDate.month,
            widget.endDate.day,
            23,
            59,
            59,
          );
          return metrics
              .where(
                (m) =>
                    !m.date.isBefore(widget.startDate) &&
                    !m.date.isAfter(endOfDay),
              )
              .toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GrowthMetrics>>(
      future: _growthMetricsFuture,
      builder: (context, futureSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _historicalMeasurementsStream,
          builder: (context, streamSnapshot) {
            if (streamSnapshot.connectionState == ConnectionState.waiting ||
                futureSnapshot.connectionState == ConnectionState.waiting) {
              return _buildSkeletonLoader();
            }

            if (streamSnapshot.hasError) {
              return Center(child: Text("Error: ${streamSnapshot.error}"));
            }

            final docs = streamSnapshot.data?.docs ?? [];
            final growthMetrics = futureSnapshot.data ?? [];

            if (docs.isEmpty && growthMetrics.isEmpty) {
              return _buildEmptyState();
            }

            final physicalData = TrendsDataService.getNormalizedParameters(
              docs,
              widget.species,
              ['Temperature', 'Salinity', 'Transparency'],
            );

            final chemicalData = TrendsDataService.getNormalizedParameters(
              docs,
              widget.species,
              [
                'pH Level',
                'Dissolved Oxygen',
                'Nitrate',
                'Nitrite',
                'Ammonia',
                'Carbon dioxide',
                'Magnesium',
                'Calcium',
                'Total Alkalinity',
              ],
            );

            final biologicalData = TrendsDataService.getNormalizedParameters(
              docs,
              widget.species,
              ['Phytoplankton', 'Bacterial'],
            );

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                PhysicalParametersChart(
                  normalizedData: physicalData,
                  species: widget.species,
                ),
                ChemicalParametersChart(
                  normalizedData: chemicalData,
                  species: widget.species,
                ),
                BiologicalParametersChart(
                  normalizedData: biologicalData,
                  species: widget.species,
                ),
                FishGainsChart(metrics: growthMetrics),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.blueGrey.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 64,
              color: Colors.blueGrey.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Data Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No measurements recorded for the selected date range.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
