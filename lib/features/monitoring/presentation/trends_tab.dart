import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';
import 'package:pondstat/features/monitoring/presentation/trends_data_service.dart';
import 'package:pondstat/features/monitoring/presentation/parameter_chart_card.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/physical_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/chemical_parameters_chart_one.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/chemical_parameters_chart_two.dart';

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
  late Stream<QuerySnapshot<Map<String, dynamic>>> _historicalMeasurementsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant TrendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _initStream();
    }
  }

  void _initStream() {
    _historicalMeasurementsStream = FirestoreHelper.getMeasurementsByDateRange(
      widget.pondId,
      widget.startDate,
      widget.endDate,
    ).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _historicalMeasurementsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return _buildSkeletonLoader();
              }

              if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildEmptyState();
              }

              final physicalData = TrendsDataService.getNormalizedParameters(
                docs,
                widget.species,
                ['Temperature', 'Salinity', 'Transparency'],
              );
              
              final chemicalOneData = TrendsDataService.getNormalizedParameters(
                docs,
                widget.species,
                ['pH Level', 'Dissolved Oxygen', 'Nitrate', 'Nitrite', 'Ammonia', 'Carbon dioxide'],
              );
              
              final chemicalTwoData = TrendsDataService.getNormalizedParameters(
                docs,
                widget.species,
                ['Magnesium', 'Calcium', 'Total Alkalinity'],
              );

              final statsList = TrendsDataService.processMeasurements(
                docs,
                widget.species,
              );

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                itemCount: statsList.length + 3,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return PhysicalParametersChart(
                      normalizedData: physicalData,
                      species: widget.species,
                    );
                  }
                  if (index == 1) {
                    return ChemicalParametersChartOne(
                      normalizedData: chemicalOneData,
                      species: widget.species,
                    );
                  }
                  if (index == 2) {
                    return ChemicalParametersChartTwo(
                      normalizedData: chemicalTwoData,
                      species: widget.species,
                    );
                  }
                  
                  return ParameterChartCard(
                    stats: statsList[index - 3],
                    species: widget.species,
                  );
                },
              );
            },
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
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
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.blueGrey.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.analytics_outlined, size: 64, color: Colors.blueGrey.withValues(alpha: 0.4)),
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
