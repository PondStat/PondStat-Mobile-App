import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/periodic_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/measurement_list_view.dart';
import 'package:pondstat/features/monitoring/presentation/record_data_sheet.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/services/safety_service.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class WaterQualityPage extends StatefulWidget {
  final String pondId;
  final String pondName;
  final String species;
  final bool canEdit;
  final DateTime selectedDay;

  const WaterQualityPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.canEdit,
    required this.selectedDay,
  });

  @override
  State<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends State<WaterQualityPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MonitoringRepository _repository = MonitoringRepository();
  final SafetyService _safetyService = SafetyService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveData({
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
    required Map<String, List<double>> replicateValues,
    String? notes,
  }) async {
    try {
      await _repository.saveMeasurement(
        pondId: widget.pondId,
        label: label,
        unit: unit,
        timeString: timeString,
        averageValue: averageValue,
        type: type,
        pointValues: pointValues,
        replicateValues: replicateValues,
        selectedDay: widget.selectedDay,
        notes: notes,
      );

      final parameterItem = MonitoringParameters.getParameterByLabel(label, widget.species);
      if (parameterItem != null) {
        await _safetyService.checkAndNotify(
          parameter: parameterItem,
          value: averageValue,
          pondName: widget.pondName,
        );
      }

      if (mounted) {
        SnackbarHelper.show(context, "Data recorded", backgroundColor: Colors.green);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, "Error: $e", backgroundColor: Colors.red);
      }
    }
  }

  void _showAddDataOverlay() {
    if (!widget.canEdit) {
      SnackbarHelper.show(context, 'Permissions required to add data.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDataSheet(
        tabIndex: _tabController.index,
        onSave: _handleSaveData,
        species: widget.species,
      ),
    );
  }

  Widget _buildTabContent(String type, String dateKey) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: PeriodicParametersChart(
              pondId: widget.pondId,
              species: widget.species,
              type: type,
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: true,
          child: MeasurementListView(
            pondId: widget.pondId,
            type: type,
            dateKey: dateKey,
            canEdit: widget.canEdit,
            onEdit: (docs) {
              // Implementation here for editing if needed, using the one from data_monitoring or keeping simple
            },
            primaryBlue: const Color(0xFF0A74DA),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Water Quality"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Daily"),
            Tab(text: "Weekly"),
            Tab(text: "Biweekly"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTabContent('daily', dateKey),
          _buildTabContent('weekly', dateKey),
          _buildTabContent('biweekly', dateKey),
        ],
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _showAddDataOverlay,
              icon: const Icon(Icons.add),
              label: const Text("Record Data"),
            )
          : null,
    );
  }
}
