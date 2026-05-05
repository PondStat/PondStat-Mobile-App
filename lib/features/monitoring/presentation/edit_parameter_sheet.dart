import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class EditParameterSheet extends StatefulWidget {
  final List<DocumentSnapshot> docs;
  final String pondId;
  final String species;
  final MonitoringRepository repository;
  final VoidCallback onSave;

  const EditParameterSheet({
    super.key,
    required this.docs,
    required this.pondId,
    required this.species,
    required this.repository,
    required this.onSave,
  });

  @override
  State<EditParameterSheet> createState() => _EditParameterSheetState();
}

class _EditParameterSheetState extends State<EditParameterSheet> {
  final List<String> points = const ['A', 'B', 'C', 'D'];
  final List<int> replicates = const [1, 2, 3];
  late final Map<String, Map<String, TextEditingController>> groupControllers;
  late final Map<String, TextEditingController> notesControllers;
  bool _isSaving = false;
  bool _isDeleting = false;

  final Color primaryBlue = const Color(0xFF0A74DA);

  @override
  void initState() {
    super.initState();
    groupControllers = {};
    notesControllers = {};

    for (var doc in widget.docs) {
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
  }

  @override
  void dispose() {
    for (var docControllers in groupControllers.values) {
      for (var controller in docControllers.values) {
        controller.dispose();
      }
    }
    for (var controller in notesControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleBatchDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete"),
        content: const Text(
          "Are you sure you want to delete these measurements?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
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

    setState(() => _isDeleting = true);

    try {
      for (var doc in widget.docs) {
        await widget.repository.deleteMeasurement(
          pondId: widget.pondId,
          measurementId: doc.id,
          currentData: doc.data() as Map<String, dynamic>,
        );
      }
      if (mounted) {
        widget.onSave();
        Navigator.pop(context); // close the edit sheet
        SnackbarHelper.show(context, "Measurements deleted");
      }
    } catch (e) {
      if (mounted)
        SnackbarHelper.show(context, "Error: $e", backgroundColor: Colors.red);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _handleBatchUpdateWithReplicates() async {
    setState(() => _isSaving = true);

    final Map<String, Map<String, double>> updatedPointValues = {};
    final Map<String, Map<String, List<double>>> updatedReplicateValues = {};
    final Map<String, String?> updatedNotes = {};

    for (var doc in widget.docs) {
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
      await widget.repository.updateMeasurementsWithReplicates(
        pondId: widget.pondId,
        docs: widget.docs,
        updatedPointValues: updatedPointValues,
        updatedReplicateValues: updatedReplicateValues,
        updatedNotes: updatedNotes,
      );
      if (mounted) {
        widget.onSave();
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
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _calculateEditReplicateAverage(
    Map<String, TextEditingController> controllers,
    String point,
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
    TextEditingController notesController, {
    bool isSinglePoint = false,
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
              child: PondStatTextField(
                controller: controllers['A-1']!,
                label: 'Value',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
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
                                onChanged: (_) => setState(() {}),
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
          PondStatTextField(
            controller: notesController,
            label: 'Notes or Findings (Optional)',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Measurements",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${widget.docs.length} Parameter${widget.docs.length > 1 ? 's' : ''}",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: widget.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final paramItem = MonitoringParameters.getParameterByLabel(
                    data['parameter'],
                    widget.species,
                  );
                  return _buildEditReplicateGroup(
                    doc,
                    groupControllers[doc.id]!,
                    notesControllers[doc.id]!,
                    isSinglePoint: paramItem?.isSinglePoint ?? false,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: _isSaving || _isDeleting ? null : _handleBatchDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                ),
                label: const Text(
                  "Delete All",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: PrimaryButton(
                  text: "Save Changes",
                  isLoading: _isSaving,
                  onPressed: _isDeleting
                      ? null
                      : _handleBatchUpdateWithReplicates,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
