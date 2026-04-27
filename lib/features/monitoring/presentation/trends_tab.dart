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

  const TrendsTab({super.key, required this.pondId, required this.species});

  @override
  State<TrendsTab> createState() => _TrendsTabState();
}

class _TrendsTabState extends State<TrendsTab> {
  int _selectedDays = 7;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _historicalMeasurementsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  @override
  void didUpdateWidget(covariant TrendsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _initStream();
    }
  }

  void _initStream() {
    _historicalMeasurementsStream = FirestoreHelper.getHistoricalMeasurements(
      widget.pondId,
      _selectedDays,
    ).snapshots();
  }

  void _updatePeriod(int days) {
    if (_selectedDays != days) {
      setState(() {
        _selectedDays = days;
        _initStream();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildPeriodSelector(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _historicalMeasurementsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
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
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPeriodChip(7, "7 Days"),
          const SizedBox(width: 12),
          _buildPeriodChip(30, "30 Days"),
          const SizedBox(width: 12),
          _buildPeriodChip(90, "3 Months"),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(int days, String label) {
    final isSelected = _selectedDays == days;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.white : Colors.grey.shade600,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _updatePeriod(days);
      },
      selectedColor: const Color(0xFF0A74DA),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? const Color(0xFF0A74DA) : Colors.grey.shade200,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No data for this period",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
