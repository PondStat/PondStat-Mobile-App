import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/core/widgets/destructive_dialog.dart';

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
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    groupControllers = {};
    notesControllers = {};

    for (var doc in widget.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
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

    for (var docControllers in groupControllers.values) {
      for (var controller in docControllers.values) {
        controller.addListener(_checkDirtyState);
      }
    }
    for (var controller in notesControllers.values) {
      controller.addListener(_checkDirtyState);
    }
  }

  @override
  void dispose() {
    for (var docControllers in groupControllers.values) {
      for (var controller in docControllers.values) {
        controller.removeListener(_checkDirtyState);
        controller.dispose();
      }
    }
    for (var controller in notesControllers.values) {
      controller.removeListener(_checkDirtyState);
      controller.dispose();
    }
    super.dispose();
  }

  void _checkDirtyState() {
    bool isNowDirty = false;
    for (var doc in widget.docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final replicateValuesMap =
          data['replicateValues'] as Map<String, dynamic>? ?? {};
      final initialNote = data['notes'] as String? ?? '';

      if (notesControllers[doc.id]?.text != initialNote) {
        isNowDirty = true;
        break;
      }

      for (var p in points) {
        final replicatesList = replicateValuesMap[p] as List<dynamic>? ?? [];
        for (var r in replicates) {
          final key = '$p-$r';
          final initialValue = r <= replicatesList.length
              ? replicatesList[r - 1].toString()
              : '';
          if (groupControllers[doc.id]?[key]?.text != initialValue) {
            isNowDirty = true;
            break;
          }
        }
        if (isNowDirty) break;
      }
      if (isNowDirty) break;
    }

    if (_isDirty != isNowDirty) {
      setState(() {
        _isDirty = isNowDirty;
      });
    }
  }

  Future<bool?> _showDiscardDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllFields() {
    setState(() {
      for (var controllersMap in groupControllers.values) {
        for (var controller in controllersMap.values) {
          controller.clear();
        }
      }
      for (var controller in notesControllers.values) {
        controller.clear();
      }
      _isDirty = true;
    });
  }

  void _handleBatchDelete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestructiveDialog(
        title: "Clear All Fields?",
        content: "Are you sure you want to clear all input fields in this sheet? You will need to click 'Save Changes' to apply this to the database.",
        confirmText: "Clear All",
        onConfirm: () async {
          _clearAllFields();
        },
      ),
    );
  }

  Future<void> _handleBatchUpdateWithReplicates() async {
    if (!_isDirty) return;

    // Validate that all entered values are valid numbers (typo safety)
    for (var doc in widget.docs) {
      final controllersMap = groupControllers[doc.id]!;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final paramName = data['parameter'] ?? 'Parameter';

      for (var p in points) {
        for (var r in replicates) {
          final key = '$p-$r';
          final textVal = controllersMap[key]?.text.trim() ?? '';
          if (textVal.isNotEmpty) {
            final val = double.tryParse(textVal);
            if (val == null) {
              final paramItem = MonitoringParameters.getParameterByLabel(
                paramName,
                widget.species,
              );
              final isSinglePoint = paramItem?.isSinglePoint ?? false;
              final fieldDesc = isSinglePoint ? "Value" : "Point $p, Replicate $r";
              SnackbarHelper.showError(
                context,
                "Invalid value for $paramName ($fieldDesc): '$textVal' is not a valid number",
              );
              return;
            }
          }
        }
      }
    }

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

      updatedPointValues[doc.id] = newPointValues;
      updatedReplicateValues[doc.id] = newReplicateValues;
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
        SnackbarHelper.showSuccess(context, "Measurements updated");
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Error: $e");
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
    TextEditingController notesController,
    ColorScheme colorScheme, {
    bool isSinglePoint = false,
  }) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${data['parameter']} (${data['unit'] ?? ''})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
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
                          color: colorScheme.onSurfaceVariant,
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,\-]'),
                                  ),
                                ],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: InputDecoration(
                                  labelText: "R${replicates[rIdx]}",
                                  isDense: true,
                                  filled: true,
                                  fillColor:
                                      colorScheme.surfaceContainerHighest,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: colorScheme.outlineVariant,
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
                        color: colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
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
                              color: colorScheme.onSurfaceVariant,
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
                              color: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: PopScope(
        canPop: !_isDirty,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          final shouldPop = await _showDiscardDialog();
          if (shouldPop == true) {
            if (context.mounted) {
              Navigator.pop(context);
            }
          }
        },
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
                  color: colorScheme.outlineVariant,
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
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${widget.docs.length} Parameter${widget.docs.length > 1 ? 's' : ''}",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final paramItem = MonitoringParameters.getParameterByLabel(
                      data['parameter'],
                      widget.species,
                    );
                    return _buildEditReplicateGroup(
                      doc,
                      groupControllers[doc.id]!,
                      notesControllers[doc.id]!,
                      colorScheme,
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
                  onPressed: _isSaving
                      ? null
                      : _handleBatchDelete,
                  icon: const Icon(
                    Icons.clear_all_rounded,
                    color: Colors.red,
                  ),
                  label: const Text(
                    "Clear All",
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
                    onPressed: !_isDirty
                        ? null
                        : _handleBatchUpdateWithReplicates,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
