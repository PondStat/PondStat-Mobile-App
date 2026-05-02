import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class RecordDataSheet extends StatefulWidget {
  final int tabIndex;
  final String species;
  final Future<void> Function({
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
    required Map<String, List<double>> replicateValues,
    String? notes,
  })
  onSave;
  final List<ParameterItem>? customParams;
  final String? customType;

  const RecordDataSheet({
    super.key,
    required this.tabIndex,
    required this.onSave,
    required this.species,
    this.customParams,
    this.customType,
  });

  @override
  State<RecordDataSheet> createState() => _RecordDataSheetState();
}

class _RecordDataSheetState extends State<RecordDataSheet> {
  ParameterItem? selectedParameter;
  String? selectedDocId;
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> points = const ['A', 'B', 'C', 'D'];
  final List<int> replicates = const [1, 2, 3];
  late final Map<String, TextEditingController> valueControllers;
  late final Map<String, FocusNode> focusNodes;
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  final MonitoringRepository _repository = MonitoringRepository();

  final Color primaryBlue = const Color(0xFF0A74DA);
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  Color get textMuted => Theme.of(context).colorScheme.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    // Create controllers for each replicate of each point
    valueControllers = {};
    focusNodes = {};

    for (var p in points) {
      for (var r in replicates) {
        final key = '$p-$r';
        valueControllers[key] = TextEditingController();
        focusNodes[key] = FocusNode();
      }
    }

    for (var controller in valueControllers.values) {
      controller.addListener(() => setState(() {}));
    }
    for (var node in focusNodes.values) {
      node.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (var controller in valueControllers.values) {
      controller.dispose();
    }
    for (var node in focusNodes.values) {
      node.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  // --- Logic ---

  double? _calculatePointAverage(String point) {
    double sum = 0;
    int count = 0;

    for (var r in replicates) {
      final key = '$point-$r';
      final textVal = valueControllers[key]!.text.trim();
      if (textVal.isNotEmpty) {
        final val = double.tryParse(textVal);
        if (val != null) {
          sum += val;
          count++;
        }
      }
    }

    if (count == 0) return null;
    return double.parse((sum / count).toStringAsFixed(2));
  }

  void _processAndSaveForm() async {
    if (selectedParameter == null || _isSaving) return;

    double totalSum = 0;
    int pointsWithData = 0;
    Map<String, double> pointValues = {};
    Map<String, List<double>> replicateValues = {};

    // Calculate average for each point
    for (var p in points) {
      final pointAvg = _calculatePointAverage(p);
      if (pointAvg != null) {
        // Validate against min/max
        if (selectedParameter!.minVal != null &&
            pointAvg < selectedParameter!.minVal!) {
          SnackbarHelper.show(
            context,
            "Point $p average is below the minimum (${selectedParameter!.minVal})",
            backgroundColor: Colors.red,
          );
          focusNodes['$p-1']?.requestFocus();
          return;
        }
        if (selectedParameter!.maxVal != null &&
            pointAvg > selectedParameter!.maxVal!) {
          SnackbarHelper.show(
            context,
            "Point $p average is above the maximum (${selectedParameter!.maxVal})",
            backgroundColor: Colors.red,
          );
          focusNodes['$p-1']?.requestFocus();
          return;
        }
        pointValues[p] = pointAvg;
        totalSum += pointAvg;
        pointsWithData++;

        // Collect replicate values for this point
        final replicates = <double>[];
        for (var r in this.replicates) {
          final key = '$p-$r';
          final textVal = valueControllers[key]!.text.trim();
          if (textVal.isNotEmpty) {
            final val = double.tryParse(textVal);
            if (val != null) {
              replicates.add(val);
            }
          }
        }
        if (replicates.isNotEmpty) {
          replicateValues[p] = replicates;
        }
      }
    }

    if (pointsWithData == 0) {
      SnackbarHelper.show(
        context,
        "Please enter at least one valid replicate value",
        backgroundColor: Colors.orange.shade700,
      );
      return;
    }

    setState(() => _isSaving = true);
    double avg = double.parse((totalSum / pointsWithData).toStringAsFixed(2));
    String type =
        widget.customType ?? ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    try {
      await widget.onSave(
        label: selectedParameter!.label,
        unit: selectedParameter!.unit,
        timeString: selectedTime.format(context),
        averageValue: avg,
        type: type,
        pointValues: pointValues,
        replicateValues: replicateValues,
        notes: _notesController.text.trim(),
      );

      HapticFeedback.heavyImpact();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          "Failed to save: $e",
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showCreateParameterDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "New Parameter",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PondStatTextField(
              controller: nameController,
              label: "Parameter Name",
              hint: "e.g., Turbidity",
              prefixIcon: Icons.science_outlined,
            ),
            const SizedBox(height: 12),
            PondStatTextField(
              controller: unitController,
              label: "Unit (Optional)",
              hint: "e.g., NTU",
              prefixIcon: Icons.straighten_rounded,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                String type =
                    widget.customType ??
                    ['daily', 'weekly', 'biweekly'][widget.tabIndex];
                await _repository.addCustomParameter(
                  label: nameController.text.trim(),
                  unit: unitController.text.trim(),
                  type: type,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text(
              "Create",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteParameter() {
    if (selectedDocId == null || selectedParameter == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text(
              "Delete Parameter",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          "Delete '${selectedParameter!.label}'? This will remove it for everyone.",
          style: TextStyle(color: textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final idToDelete = selectedDocId!;
              await _repository.deleteCustomParameter(idToDelete);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() {
                  selectedParameter = null;
                  selectedDocId = null;
                });
                SnackbarHelper.show(
                  context,
                  "Parameter deleted",
                  backgroundColor: Colors.grey.shade800,
                );
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildParamTile({required ParameterItem param, String? docId}) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          selectedParameter = param;
          selectedDocId = docId;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) focusNodes['A-1']?.requestFocus();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [param.color.withValues(alpha: 0.85), param.color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: param.color.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(param.icon, color: Colors.white, size: 20),
            ),
            Text(
              param.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.2,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showCreateParameterDialog();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 28),
            const SizedBox(height: 6),
            Text(
              "Custom",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterGrid() {
    List<ParameterItem> hardcodedParams =
        widget.customParams ??
        MonitoringParameters.getParametersByIndex(
          widget.tabIndex,
          widget.species,
        );
    String type =
        widget.customType ?? ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    if (type == 'growth') {
      List<Widget> gridItems = hardcodedParams
          .map((p) => _buildParamTile(param: p))
          .toList();
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.95,
        ),
        itemCount: gridItems.length,
        itemBuilder: (context, i) => gridItems[i],
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.customParametersCollection
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        List<Widget> gridItems = hardcodedParams
            .map((p) => _buildParamTile(param: p))
            .toList();
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            gridItems.add(
              _buildParamTile(
                param: ParameterItem(
                  label: data['label'],
                  unit: data['unit'] ?? '',
                  icon: Icons.dashboard_customize_rounded,
                  color: Colors.blueGrey,
                ),
                docId: doc.id,
              ),
            );
          }
        }
        gridItems.add(_buildAddNewButton());
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: gridItems.length,
          itemBuilder: (context, i) => gridItems[i],
        );
      },
    );
  }

  Widget _buildInputForm() {
    final bool hasRange =
        selectedParameter!.minVal != null && selectedParameter!.maxVal != null;
    final Color themeColor = selectedParameter!.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      selectedParameter!.icon,
                      color: themeColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "RECORDING",
                          style: TextStyle(
                            color: themeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          selectedParameter!.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                            color: textDark,
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (selectedDocId != null)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                onPressed: _confirmDeleteParameter,
              ),
          ],
        ),
        const SizedBox(height: 28),
        _buildTimePickerCard(themeColor),
        const SizedBox(height: 32),
        _buildDataPointsHeader(hasRange, themeColor),
        const SizedBox(height: 16),
        _buildDataPointInputs(themeColor),
        const SizedBox(height: 24),
        PondStatTextField(
          controller: _notesController,
          label: "Notes or Findings (Optional)",
          hint: "e.g., Water looks slightly cloudy today",
          prefixIcon: Icons.notes_rounded,
          maxLines: 3,
        ),
        const SizedBox(height: 32),

        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: themeColor),
          ),
          child: PrimaryButton(
            text: 'Save Measurement',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isSaving,
            onPressed: _processAndSaveForm,
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickerCard(Color themeColor) {
    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) {
          HapticFeedback.selectionClick();
          setState(() => selectedTime = picked);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white10
                : Colors.grey.shade100,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  selectedTime.format(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: textDark,
                  ),
                ),
              ],
            ),
            Text(
              "Edit",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPointsHeader(bool hasRange, Color themeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Data Points",
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: textDark,
                fontSize: 18,
              ),
            ),
            if (hasRange) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Safe Range: ${selectedParameter!.minVal} - ${selectedParameter!.maxVal}",
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else if (selectedParameter!.minVal != null) ...[
              const SizedBox(height: 4),
              Text(
                "Minimum: ${selectedParameter!.minVal}",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else if (selectedParameter!.maxVal != null) ...[
              const SizedBox(height: 4),
              Text(
                "Maximum: ${selectedParameter!.maxVal}",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        if (selectedParameter!.unit.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              selectedParameter!.unit,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDataPointInputs(Color themeColor) {
    if (selectedParameter!.isSinglePoint) {
      // For single point parameters, show 1 input value (treated as Point A, Replicate 1 behind the scenes)
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildReplicateInput('A', 1, themeColor, customLabel: "Value"),
      );
    }

    // For multi-point parameters, show each point with its 3 replicates and average
    return Column(
      children: [
        for (int pIdx = 0; pIdx < points.length; pIdx++)
          Padding(
            padding: EdgeInsets.only(bottom: pIdx < points.length - 1 ? 24 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Point header
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Point ${points[pIdx]}",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textDark,
                    ),
                  ),
                ),
                // Replicate inputs
                Row(
                  children: [
                    for (int rIdx = 0; rIdx < replicates.length; rIdx++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: rIdx < replicates.length - 1 ? 8 : 0,
                          ),
                          child: _buildReplicateInput(
                            points[pIdx],
                            replicates[rIdx],
                            themeColor,
                            isCompact: true,
                          ),
                        ),
                      ),
                  ],
                ),
                // Average display for this point
                const SizedBox(height: 10),
                _buildAverageDisplay(points[pIdx], themeColor),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReplicateInput(
    String point,
    int replicate,
    Color themeColor, {
    bool isCompact = false,
    String? customLabel,
  }) {
    final key = '$point-$replicate';
    final bool isFocused = focusNodes[key]?.hasFocus ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? themeColor : Colors.transparent,
          width: isFocused ? 2 : 0,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: valueControllers[key],
        focusNode: focusNodes[key],
        keyboardType: selectedParameter!.keyboardType,
        textInputAction: TextInputAction.next,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: isCompact ? 14 : 18,
          color: textDark,
        ),
        decoration: InputDecoration(
          labelText:
              customLabel ??
              (isCompact ? "R$replicate" : "Replicate $replicate"),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: TextStyle(
            color: isFocused ? themeColor : Colors.grey.shade500,
            fontWeight: FontWeight.w800,
            fontSize: isCompact ? 11 : 12,
          ),
          hintText: selectedParameter!.hint.isEmpty
              ? ''
              : selectedParameter!.hint.split(' ').last,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(top: 8, bottom: 12),
        ),
      ),
    );
  }

  Widget _buildAverageDisplay(String point, Color themeColor) {
    final average = _calculatePointAverage(point);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart_rounded, color: themeColor, size: 18),
              const SizedBox(width: 8),
              Text(
                "Average for Point $point",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: textMuted,
                ),
              ),
            ],
          ),
          Text(
            average != null ? average.toString() : "—",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: themeColor,
            ),
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
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            _buildSheetHeader(),
            const SizedBox(height: 16),
            _buildContentSwitcher(),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (selectedParameter != null)
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: textDark),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                selectedParameter = null;
                selectedDocId = null;
              });
            },
          ),
        Expanded(
          child: Text(
            selectedParameter == null ? "Select Parameter" : "Enter Data",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textDark,
              letterSpacing: -0.5,
            ),
          ),
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, size: 20, color: textMuted),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildContentSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.05, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: selectedParameter == null
          ? KeyedSubtree(
              key: const ValueKey('grid'),
              child: _buildParameterGrid(),
            )
          : KeyedSubtree(key: const ValueKey('form'), child: _buildInputForm()),
    );
  }
}
