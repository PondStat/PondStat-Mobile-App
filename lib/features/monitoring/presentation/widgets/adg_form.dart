import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/calculated_result_box.dart';
import 'package:pondstat/features/monitoring/utils/growth_calculators.dart';

class AdgForm extends StatefulWidget {
  final void Function(double? calculatedValue) onChanged;

  const AdgForm({super.key, required this.onChanged});

  @override
  State<AdgForm> createState() => _AdgFormState();
}

class _AdgFormState extends State<AdgForm> {
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _previousCtrl = TextEditingController();
  final TextEditingController _daysCtrl = TextEditingController();

  double? _calculateADG() {
    return GrowthCalculators.calculateADG(
      currentAbw: double.tryParse(_currentCtrl.text),
      previousAbw: double.tryParse(_previousCtrl.text),
      days: double.tryParse(_daysCtrl.text),
    );
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged(_calculateADG());
  }

  @override
  void initState() {
    super.initState();
    _currentCtrl.addListener(_onChanged);
    _previousCtrl.addListener(_onChanged);
    _daysCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _previousCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PondStatTextField(
          controller: _currentCtrl,
          label: "Current ABW (g)",
          hint: "e.g., 15",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _previousCtrl,
          label: "Previous ABW (g)",
          hint: "e.g., 10",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _daysCtrl,
          label: "Number of days between samples",
          hint: "e.g., 7",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        CalculatedResultBox(
          title: "Calculated ADG:",
          value: _calculateADG(),
          unit: "g/day",
          color: Colors.blue,
        ),
      ],
    );
  }
}
