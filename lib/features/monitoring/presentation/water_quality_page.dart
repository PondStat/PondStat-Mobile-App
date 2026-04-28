import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/measurement_list_view.dart';
import 'package:pondstat/features/monitoring/presentation/record_data_sheet.dart';
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

      final parameterItem = MonitoringParameters.getParameterByLabel(
        label,
        widget.species,
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

  Future<void> _handleBatchDelete(List<DocumentSnapshot> docs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete"),
        content: const Text("Delete this measurement?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      for (var doc in docs) {
        await _repository.deleteMeasurement(
          pondId: widget.pondId,
          measurementId: doc.id,
          currentData: doc.data() as Map<String, dynamic>,
        );
      }
      if (mounted) {
        Navigator.pop(context); // close the edit dialog
        SnackbarHelper.show(context, "Measurements deleted");
      }
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, "Error: $e");
    }
  }

  Future<void> _handleBatchUpdateWithReplicates(
    List<DocumentSnapshot> docs,
    Map<String, Map<String, TextEditingController>> groupControllers,
    Map<String, TextEditingController> notesControllers,
    List<String> points,
    List<int> replicates,
  ) async {
    final Map<String, Map<String, double>> updatedPointValues = {};
    final Map<String, Map<String, List<double>>> updatedReplicateValues = {};
    final Map<String, String?> updatedNotes = {};

    for (var doc in docs) {
      final controllersMap = groupControllers[doc.id]!;
      Map<String, double> newPointValues = {};
      Map<String, List<double>> newReplicateValues = {};

      final newNote = notesControllers[doc.id]?.text.trim();
      updatedNotes[doc.id] = newNote != null && newNote.isNotEmpty
          ? newNote
          : null;

      for (var p in points) {
        final replicatesList = <double>[];
        for (var r in replicates) {
          final key = '$p-$r';
          final val = double.tryParse(controllersMap[key]?.text ?? '');
          if (val != null) {
            replicatesList.add(val);
          }
        }

        if (replicatesList.isNotEmpty) {
          newReplicateValues[p] = replicatesList;
          final avg = double.parse(
            (replicatesList.reduce((a, b) => a + b) / replicatesList.length)
                .toStringAsFixed(2),
          );
          newPointValues[p] = avg;
        }
      }

      if (newPointValues.isNotEmpty) {
        updatedPointValues[doc.id] = newPointValues;
        updatedReplicateValues[doc.id] = newReplicateValues;
      }
    }

    try {
      await _repository.updateMeasurementsWithReplicates(
        pondId: widget.pondId,
        docs: docs,
        updatedPointValues: updatedPointValues,
        updatedReplicateValues: updatedReplicateValues,
        updatedNotes: updatedNotes,
      );
      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.show(
          context,
          "Measurements updated",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, "Error: $e", backgroundColor: Colors.red);
      }
    }
  }

  String _calculateEditReplicateAverage(
    Map<String, TextEditingController> controllers,
    String point,
    List<int> replicates,
  ) {
    double sum = 0;
    int count = 0;
    for (var r in replicates) {
      final key = '$point-$r';
      final text = controllers[key]?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final val = double.tryParse(text);
        if (val != null) {
          sum += val;
          count++;
        }
      }
    }
    if (count == 0) return "—";
    return double.parse((sum / count).toStringAsFixed(2)).toString();
  }

  Widget _buildEditReplicateGroup(
    DocumentSnapshot doc,
    Map<String, TextEditingController> controllers,
    TextEditingController notesController,
    List<String> points,
    List<int> replicates, {
    bool isSinglePoint = false,
    required void Function(VoidCallback) setDialogState,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${data['parameter']} (${data['unit'] ?? ''})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (isSinglePoint)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controllers['A-1'],
                      onChanged: (_) => setDialogState(() {}),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Value',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (int pIdx = 0; pIdx < points.length; pIdx++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: pIdx < points.length - 1 ? 20 : 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        "Point ${points[pIdx]}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (int rIdx = 0; rIdx < replicates.length; rIdx++)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: rIdx < replicates.length - 1 ? 8 : 0,
                              ),
                              child: TextField(
                                controller:
                                    controllers['${points[pIdx]}-${replicates[rIdx]}'],
                                onChanged: (_) => setDialogState(() {}),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: "R${replicates[rIdx]}",
                                  isDense: true,
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: primaryBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Avg:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _calculateEditReplicateAverage(
                              controllers,
                              points[pIdx],
                              replicates,
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes or Findings (Optional)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDataDialog(List<DocumentSnapshot> docs) {
    if (!widget.canEdit) return;

    final List<String> points = const ['A', 'B', 'C', 'D'];
    final List<int> replicates = const [1, 2, 3];
    final Map<String, Map<String, TextEditingController>> groupControllers = {};
    final Map<String, TextEditingController> notesControllers = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final replicateValuesMap =
          data['replicateValues'] as Map<String, dynamic>? ?? {};
      groupControllers[doc.id] = {};
      notesControllers[doc.id] = TextEditingController(
        text: data['notes'] as String? ?? '',
      );

      for (var p in points) {
        for (var r in replicates) {
          final key = '$p-$r';
          final replicatesList = replicateValuesMap[p] as List<dynamic>? ?? [];
          final value = r <= replicatesList.length
              ? replicatesList[r - 1].toString()
              : '';
          groupControllers[doc.id]![key] = TextEditingController(text: value);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Edit Measurements',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final paramItem = MonitoringParameters.getParameterByLabel(
                data['parameter'],
                widget.species,
              );
              return _buildEditReplicateGroup(
                doc,
                groupControllers[doc.id]!,
                notesControllers[doc.id]!,
                points,
                replicates,
                isSinglePoint: paramItem?.isSinglePoint ?? false,
                setDialogState: setDialogState,
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _handleBatchDelete(docs),
              child: const Text(
                "Delete",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () => _handleBatchUpdateWithReplicates(
                docs,
                groupControllers,
                notesControllers,
                points,
                replicates,
              ),
              child: const Text(
                "Update",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String type, String dateKey) {
    return Column(
      children: [
        Expanded(
          child: MeasurementListView(
            pondId: widget.pondId,
            type: type,
            dateKey: dateKey,
            canEdit: widget.canEdit,
            onEdit: _showEditDataDialog,
            primaryBlue: primaryBlue,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primaryBlue,
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: primaryBlue,
            tabs: const [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Biweekly"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('daily', dateKey),
                _buildTabContent('weekly', dateKey),
                _buildTabContent('biweekly', dateKey),
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
              label: const Text("Record Data"),
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
