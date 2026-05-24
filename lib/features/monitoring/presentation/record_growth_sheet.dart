import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/abw_form.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/adg_form.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/dfr_form.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/fcr_form.dart';
import 'package:pondstat/core/widgets/discard_changes_dialog.dart';

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
  })
  onSave;

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
  double? _calculatedValue;

  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  bool _forceClose = false;

  void _updateState() => setState(() {});

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_updateState);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  bool _hasUnsavedData() {
    if (_notesController.text.isNotEmpty) return true;
    if (_calculatedValue != null) return true;
    return false;
  }

  bool get _isFormValid => _calculatedValue != null;

  void _clearAllControllers() {
    _notesController.clear();
    setState(() {
      _calculatedValue = null;
    });
  }

  void _processAndSave() async {
    if (selectedParameter == null || _isSaving || !_isFormValid) return;

    final double? finalValue = _calculatedValue;

    if (finalValue == null) {
      SnackbarHelper.showInfo(context, "Please enter valid numbers in all fields.");
      return;
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
        replicateValues: {
          'A': [finalValue],
        },
        notes: _notesController.text.trim(),
      );
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() => _forceClose = true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Failed to save: $e");
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedData()) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => const DiscardChangesDialog(
        title: 'Discard Unsaved Data?',
        content: 'You have entered data that has not been saved yet. Are you sure you want to close this sheet?',
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _forceClose,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          setState(() => _forceClose = true);
          Navigator.pop(context);
        }
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Container(
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
                      color: Theme.of(context).colorScheme.outlineVariant,
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
                        onPressed: () async {
                          if (_hasUnsavedData()) {
                            final shouldDiscard = await _onWillPop();
                            if (!shouldDiscard) return;
                          }
                          setState(() => selectedParameter = null);
                        },
                      ),
                    Expanded(
                      child: Text(
                        selectedParameter == null
                            ? "Select Parameter"
                            : "Enter Data",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (selectedParameter == null)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.5,
                        ),
                    itemCount: MonitoringParameters.samplingParameters.length,
                    itemBuilder: (context, i) {
                      final p = MonitoringParameters.samplingParameters[i];
                      return InkWell(
                        onTap: () => setState(() {
                          selectedParameter = p;
                          _clearAllControllers();
                        }),
                        child: Container(
                          decoration: BoxDecoration(
                            color: p.getColor(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: p.getColor(context).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                p.icon,
                                color: p.getColor(context),
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                p.label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: p.getColor(context),
                                ),
                              ),
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
                      Text(
                        selectedParameter!.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: selectedParameter!.getColor(context),
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (selectedParameter!.label == 'ABW')
                        AbwForm(onChanged: (val) => setState(() => _calculatedValue = val))
                      else if (selectedParameter!.label == 'ADG')
                        AdgForm(onChanged: (val) => setState(() => _calculatedValue = val))
                      else if (selectedParameter!.label == 'DFR')
                        DfrForm(onChanged: (val) => setState(() => _calculatedValue = val))
                      else if (selectedParameter!.label == 'FCR')
                        FcrForm(onChanged: (val) => setState(() => _calculatedValue = val)),

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
                        onPressed: _isFormValid ? _processAndSave : null,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
