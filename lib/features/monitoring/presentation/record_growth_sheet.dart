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

  // ABW
  final TextEditingController _abwWeightCtrl = TextEditingController();
  final TextEditingController _abwCountCtrl = TextEditingController();

  // ADG
  final TextEditingController _adgCurrentCtrl = TextEditingController();
  final TextEditingController _adgPreviousCtrl = TextEditingController();
  final TextEditingController _adgDaysCtrl = TextEditingController();

  // DFR
  final TextEditingController _dfrStockedCtrl = TextEditingController();
  final TextEditingController _dfrSurvivalCtrl = TextEditingController();
  final TextEditingController _dfrCurrentAbwCtrl = TextEditingController();
  final TextEditingController _dfrFeedingRateCtrl = TextEditingController();

  // FCR
  final TextEditingController _fcrFeedCtrl = TextEditingController();
  final TextEditingController _fcrWeightGainedCtrl = TextEditingController();

  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  void _updateState() => setState(() {});

  @override
  void initState() {
    super.initState();

    _abwWeightCtrl.addListener(_updateState);
    _abwCountCtrl.addListener(_updateState);

    _adgCurrentCtrl.addListener(_updateState);
    _adgPreviousCtrl.addListener(_updateState);
    _adgDaysCtrl.addListener(_updateState);

    _dfrStockedCtrl.addListener(_updateState);
    _dfrSurvivalCtrl.addListener(_updateState);
    _dfrCurrentAbwCtrl.addListener(_updateState);
    _dfrFeedingRateCtrl.addListener(_updateState);

    _fcrFeedCtrl.addListener(_updateState);
    _fcrWeightGainedCtrl.addListener(_updateState);

    _notesController.addListener(_updateState);
  }

  @override
  void dispose() {
    _abwWeightCtrl.dispose();
    _abwCountCtrl.dispose();

    _adgCurrentCtrl.dispose();
    _adgPreviousCtrl.dispose();
    _adgDaysCtrl.dispose();

    _dfrStockedCtrl.dispose();
    _dfrSurvivalCtrl.dispose();
    _dfrCurrentAbwCtrl.dispose();
    _dfrFeedingRateCtrl.dispose();

    _fcrFeedCtrl.dispose();
    _fcrWeightGainedCtrl.dispose();

    _notesController.dispose();
    super.dispose();
  }

  bool _hasUnsavedData() {
    if (_notesController.text.isNotEmpty) return true;

    if (selectedParameter?.label == 'ABW') {
      return _abwWeightCtrl.text.isNotEmpty || _abwCountCtrl.text.isNotEmpty;
    } else if (selectedParameter?.label == 'ADG') {
      return _adgCurrentCtrl.text.isNotEmpty ||
          _adgPreviousCtrl.text.isNotEmpty ||
          _adgDaysCtrl.text.isNotEmpty;
    } else if (selectedParameter?.label == 'DFR') {
      return _dfrStockedCtrl.text.isNotEmpty ||
          _dfrSurvivalCtrl.text.isNotEmpty ||
          _dfrCurrentAbwCtrl.text.isNotEmpty ||
          _dfrFeedingRateCtrl.text.isNotEmpty;
    } else if (selectedParameter?.label == 'FCR') {
      return _fcrFeedCtrl.text.isNotEmpty ||
          _fcrWeightGainedCtrl.text.isNotEmpty;
    }

    return false;
  }

  double? _calculateABW() {
    final w = double.tryParse(_abwWeightCtrl.text);
    final c = double.tryParse(_abwCountCtrl.text);
    if (w != null && c != null && c > 0) return w / c;
    return null;
  }

  double? _calculateADG() {
    final cur = double.tryParse(_adgCurrentCtrl.text);
    final prev = double.tryParse(_adgPreviousCtrl.text);
    final days = double.tryParse(_adgDaysCtrl.text);
    if (cur != null && prev != null && days != null && days > 0) {
      return (cur - prev) / days;
    }
    return null;
  }

  double? _calculateDFR() {
    final stocked = double.tryParse(_dfrStockedCtrl.text);
    final surv = double.tryParse(_dfrSurvivalCtrl.text);
    final abw = double.tryParse(_dfrCurrentAbwCtrl.text);
    final feedRate = double.tryParse(_dfrFeedingRateCtrl.text);
    if (stocked != null && surv != null && abw != null && feedRate != null) {
      return (stocked * (surv / 100.0) * abw * (feedRate / 100.0)) / 1000.0;
    }
    return null;
  }

  double? _calculateFCR() {
    final feed = double.tryParse(_fcrFeedCtrl.text);
    final gained = double.tryParse(_fcrWeightGainedCtrl.text);
    if (feed != null && gained != null && gained > 0) {
      return feed / gained;
    }
    return null;
  }

  bool get _isFormValid {
    if (selectedParameter == null) return false;

    if (selectedParameter!.label == 'ABW') {
      return _calculateABW() != null;
    } else if (selectedParameter!.label == 'ADG') {
      return _calculateADG() != null;
    } else if (selectedParameter!.label == 'DFR') {
      return _calculateDFR() != null;
    } else if (selectedParameter!.label == 'FCR') {
      return _calculateFCR() != null;
    }

    return false;
  }

  void _clearAllControllers() {
    _abwWeightCtrl.clear();
    _abwCountCtrl.clear();

    _adgCurrentCtrl.clear();
    _adgPreviousCtrl.clear();
    _adgDaysCtrl.clear();

    _dfrStockedCtrl.clear();
    _dfrSurvivalCtrl.clear();
    _dfrCurrentAbwCtrl.clear();
    _dfrFeedingRateCtrl.clear();

    _fcrFeedCtrl.clear();
    _fcrWeightGainedCtrl.clear();

    _notesController.clear();
  }

  void _processAndSave() async {
    if (selectedParameter == null || _isSaving || !_isFormValid) return;

    double? finalValue;

    if (selectedParameter!.label == 'ABW') {
      finalValue = _calculateABW();
    } else if (selectedParameter!.label == 'ADG') {
      finalValue = _calculateADG();
    } else if (selectedParameter!.label == 'DFR') {
      finalValue = _calculateDFR();
    } else if (selectedParameter!.label == 'FCR') {
      finalValue = _calculateFCR();
    }

    if (finalValue == null) {
      SnackbarHelper.show(
        context,
        "Please enter valid numbers in all fields.",
        backgroundColor: Colors.orange.shade700,
      );
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          "Failed to save: $e",
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAbwForm() {
    return Column(
      children: [
        PondStatTextField(
          controller: _abwWeightCtrl,
          label: "Total weight of sampled fish (g)",
          hint: "e.g., 500",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _abwCountCtrl,
          label: "Number of fish sampled",
          hint: "e.g., 50",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _buildResultBox("Calculated ABW:", _calculateABW(), "g", Colors.green),
      ],
    );
  }

  Widget _buildAdgForm() {
    return Column(
      children: [
        PondStatTextField(
          controller: _adgCurrentCtrl,
          label: "Current ABW (g)",
          hint: "e.g., 15",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _adgPreviousCtrl,
          label: "Previous ABW (g)",
          hint: "e.g., 10",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _adgDaysCtrl,
          label: "Number of days between samples",
          hint: "e.g., 7",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _buildResultBox(
          "Calculated ADG:",
          _calculateADG(),
          "g/day",
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDfrForm() {
    return Column(
      children: [
        PondStatTextField(
          controller: _dfrStockedCtrl,
          label: "Total fish stocked",
          hint: "e.g., 10000",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _dfrSurvivalCtrl,
          label: "Estimated survival rate (%)",
          hint: "e.g., 80",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _dfrCurrentAbwCtrl,
          label: "Current ABW (g)",
          hint: "e.g., 15",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _dfrFeedingRateCtrl,
          label: "Feeding rate (%)",
          hint: "e.g., 5",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 24),
        _buildResultBox(
          "Calculated DFR:",
          _calculateDFR(),
          "kg/day",
          Colors.brown,
        ),
      ],
    );
  }

  Widget _buildFcrForm() {
    return Column(
      children: [
        PondStatTextField(
          controller: _fcrFeedCtrl,
          label: "Total weight of feed given (g)",
          hint: "e.g., 2000",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _fcrWeightGainedCtrl,
          label: "Total weight gained by fish (g)",
          hint: "e.g., 1500",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 24),
        _buildResultBox("Calculated FCR:", _calculateFCR(), "", Colors.orange),
      ],
    );
  }

  Widget _buildResultBox(
    String title,
    double? value,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            value != null ? "${value.toStringAsFixed(2)} $unit" : "—",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedData()) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Unsaved Data?'),
        content: const Text(
          'You have entered data that has not been saved yet. Are you sure you want to close this sheet?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final bool shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
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
                              Icon(p.icon, color: p.getColor(context), size: 32),
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
                        _buildAbwForm()
                      else if (selectedParameter!.label == 'ADG')
                        _buildAdgForm()
                      else if (selectedParameter!.label == 'DFR')
                        _buildDfrForm()
                      else if (selectedParameter!.label == 'FCR')
                        _buildFcrForm(),

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
