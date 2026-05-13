import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/measurement_list_view.dart';
import 'package:pondstat/features/monitoring/presentation/record_data_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_parameter_sheet.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/services/safety_service.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _WaterQualityPageState extends State<WaterQualityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MonitoringRepository _repository = MonitoringRepository();
  final SafetyService _safetyService = SafetyService();

  final Color primaryBlue = const Color(0xFF0A74DA);

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
      final parameterItem = MonitoringParameters.getParameterByLabel(
        label,
        widget.species,
      );

      Map<String, dynamic>? alertPayload;
      if (parameterItem != null) {
        alertPayload = _safetyService.getAlertPayload(
          parameter: parameterItem,
          value: averageValue,
          pondName: widget.pondName,
        );
      }

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
        alert: alertPayload,
      );

      if (parameterItem != null) {
        await _safetyService.checkAndNotify(
          parameter: parameterItem,
          value: averageValue,
          pondName: widget.pondName,
        );
      }

      if (mounted) {
        SnackbarHelper.show(
          context,
          "Data recorded",
          backgroundColor: Colors.green,
        );
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

    HapticFeedback.lightImpact();

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

  void _showEditDataDialog(List<DocumentSnapshot> docs) {
    if (!widget.canEdit) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditParameterSheet(
        docs: docs,
        pondId: widget.pondId,
        species: widget.species,
        repository: _repository,
        onSave: () {
          // Trigger a rebuild if necessary, or the stream will naturally update.
        },
      ),
    );
  }

  Widget _buildTabContent(String type, String dateKey, Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: MeasurementListView(
            pondId: widget.pondId,
            type: type,
            dateKey: dateKey,
            canEdit: widget.canEdit,
            onEdit: _showEditDataDialog,
            primaryBlue: primaryColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";
    final primaryColor = Theme.of(context).colorScheme.primary;

    String fabLabel = "Record Daily";
    if (_tabController.index == 1) {
      fabLabel = "Record Weekly";
    } else if (_tabController.index == 2) {
      fabLabel = "Record Biweekly";
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: TabBar(
              isScrollable: false,
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: Colors.grey.shade400,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: "Daily"),
                Tab(text: "Weekly"),
                Tab(text: "Biweekly"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('daily', dateKey, primaryColor),
                _buildTabContent('weekly', dateKey, primaryColor),
                _buildTabContent('biweekly', dateKey, primaryColor),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              heroTag: 'water_quality_fab',
              onPressed: _showAddDataOverlay,
              icon: const Icon(Icons.add),
              label: Text(fabLabel),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
