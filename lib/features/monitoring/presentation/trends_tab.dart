import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/features/monitoring/data/trends_repository.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
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
  late Stream<QuerySnapshot<Map<String, dynamic>>> _customParamsStream;
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

    _customParamsStream = FirestoreHelper.customParametersCollection
        .snapshots();

    _growthMetricsFuture =
        GrowthRepository.calculateGrowthMetrics(widget.pondId).then((metrics) {
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
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _customParamsStream,
              builder: (context, customParamsSnapshot) {
                if (streamSnapshot.connectionState == ConnectionState.waiting ||
                    futureSnapshot.connectionState == ConnectionState.waiting ||
                    customParamsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                  return _buildSkeletonLoader();
                }

                if (streamSnapshot.hasError) {
                  return Center(child: Text("Error: ${streamSnapshot.error}"));
                }

                final docs = streamSnapshot.data?.docs ?? [];
                final growthMetrics = futureSnapshot.data ?? [];
                final customParamsDocs = customParamsSnapshot.data?.docs ?? [];

                if (docs.isEmpty && growthMetrics.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: EmptyStateCard(
                      icon: Icons.analytics_outlined,
                      title: 'No Data Found',
                      description: 'No measurements recorded for the selected date range.',
                    ),
                  );
                }

                return _buildContent(docs, growthMetrics, customParamsDocs);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildContent(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<GrowthMetrics> growthMetrics,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> customParamsDocs,
  ) {
    final List<String> customPhysical = [];
    final List<String> customChemical = [];
    final List<String> customBiological = [];

    for (var doc in customParamsDocs) {
      final data = doc.data();
      final category = data['category'] as String?;
      final label = data['label'] as String?;
      if (label != null) {
        if (category == 'Physical') customPhysical.add(label);
        if (category == 'Chemical') customChemical.add(label);
        if (category == 'Biological') customBiological.add(label);
      }
    }

    final physicalData = TrendsRepository.getNormalizedParameters(
      docs,
      widget.species,
      ['Temperature', 'Salinity', 'Transparency', ...customPhysical],
    );

    final chemicalData = TrendsRepository.getNormalizedParameters(
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
        ...customChemical,
      ],
    );

    final biologicalData = TrendsRepository.getNormalizedParameters(
      docs,
      widget.species,
      [
        'Phytoplankton',
        'Test 10-1 (Average yellow colonies)',
        'Test yellow 10-1 (CFU/ml)',
        'Test 10-2 (Average yellow colonies)',
        'Test yellow 10-2 (CFU/ml)',
        'Test 10-1 (Average green colonies)',
        'Test green 10-1 (CFU/ml)',
        'Test 10-2 (Average green colonies)',
        'Test green 10-2 (CFU/ml)',
        ...customBiological,
      ],
    );

    return ListView(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 100, // Padding to protect from FAB
      ),
      children: [
        PhysicalParametersChart(
          normalizedData: physicalData,
          species: widget.species,
          startDate: widget.startDate,
          endDate: widget.endDate,
        ),
        ChemicalParametersChart(
          normalizedData: chemicalData,
          species: widget.species,
          startDate: widget.startDate,
          endDate: widget.endDate,
        ),
        BiologicalParametersChart(
          normalizedData: biologicalData,
          species: widget.species,
          startDate: widget.startDate,
          endDate: widget.endDate,
        ),
        FishGainsChart(metrics: growthMetrics),
      ],
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
}
