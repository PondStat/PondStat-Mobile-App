import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class RecordGrowthSheet extends StatefulWidget {
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
  }) onSave;

  const RecordGrowthSheet({
    super.key,
    required this.species,
    required this.onSave,
  });

  @override
  State<RecordGrowthSheet> createState() => _RecordGrowthSheetState();
}

class _RecordGrowthSheetState extends State<RecordGrowthSheet> {
  ParameterItem? selectedParameter;
  TimeOfDay selectedTime = TimeOfDay.now();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(() => setState(() {}));
    _countController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _weightController.dispose();
    _countController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _calculateABW() {
    final w = double.tryParse(_weightController.text);
    final c = double.tryParse(_countController.text);
    if (w != null && c != null && c > 0) {
      return w / c;
    }
    return null;
  }

  void _processAndSave() async {
    if (selectedParameter == null || _isSaving) return;

    double? finalValue;

    if (selectedParameter!.label == 'ABW') {
      finalValue = _calculateABW();
      if (finalValue == null) {
        SnackbarHelper.show(context, "Please enter valid weight and count", backgroundColor: Colors.orange.shade700);
        return;
      }
    } else {
      finalValue = double.tryParse(_valueController.text);
      if (finalValue == null) {
        SnackbarHelper.show(context, "Please enter a valid value", backgroundColor: Colors.orange.shade700);
        return;
      }
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        label: selectedParameter!.label,
        unit: selectedParameter!.unit,
        timeString: selectedTime.format(context),
        averageValue: double.parse(finalValue.toStringAsFixed(2)),
        type: 'growth',
        pointValues: {'A': finalValue},
        replicateValues: {'A': [finalValue]},
        notes: _notesController.text.trim(),
      );
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, "Failed to save: $e", backgroundColor: Colors.redAccent);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12, left: 20, right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48, height: 5,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (selectedParameter != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => setState(() => selectedParameter = null),
                  ),
                Expanded(
                  child: Text(
                    selectedParameter == null ? "Select Parameter" : "Enter Data",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedParameter == null)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
                ),
                itemCount: MonitoringParameters.samplingParameters.length,
                itemBuilder: (context, i) {
                  final p = MonitoringParameters.samplingParameters[i];
                  return InkWell(
                    onTap: () => setState(() {
                      selectedParameter = p;
                      _valueController.clear();
                      _weightController.clear();
                      _countController.clear();
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.color.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p.icon, color: p.color, size: 32),
                          const SizedBox(height: 8),
                          Text(p.label, style: TextStyle(fontWeight: FontWeight.bold, color: p.color)),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(selectedParameter!.label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: selectedParameter!.color)),
                  const SizedBox(height: 24),
                  if (selectedParameter!.label == 'ABW') ...[
                    PondStatTextField(
                      controller: _weightController,
                      label: "Total weight of sampled fish (g)",
                      hint: "e.g., 500",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    PondStatTextField(
                      controller: _countController,
                      label: "Number of fish sampled (pcs)",
                      hint: "e.g., 50",
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.lightGreen.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Calculated ABW:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          Text(
                            _calculateABW() != null ? "${_calculateABW()!.toStringAsFixed(2)} g" : "—",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    PondStatTextField(
                      controller: _valueController,
                      label: "${selectedParameter!.label} Value (${selectedParameter!.unit})",
                      hint: selectedParameter!.hint,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PondStatTextField(
                    controller: _notesController,
                    label: "Notes (Optional)",
                    hint: "Any observations",
                    maxLines: 2,
                  ),
                  const SizedBox(height: 32),
                  PrimaryButton(
                    text: 'Save Measurement',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: _isSaving,
                    onPressed: _processAndSave,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
