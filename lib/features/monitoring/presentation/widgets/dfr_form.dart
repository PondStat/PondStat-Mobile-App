import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/calculated_result_box.dart';

class DfrForm extends StatefulWidget {
  final void Function(double? calculatedValue) onChanged;

  const DfrForm({super.key, required this.onChanged});

  @override
  State<DfrForm> createState() => _DfrFormState();
}

class _DfrFormState extends State<DfrForm> {
  final TextEditingController _stockedCtrl = TextEditingController();
  final TextEditingController _survivalCtrl = TextEditingController();
  final TextEditingController _currentAbwCtrl = TextEditingController();
  final TextEditingController _feedingRateCtrl = TextEditingController();

  double? _calculateDFR() {
    final stocked = double.tryParse(_stockedCtrl.text);
    final surv = double.tryParse(_survivalCtrl.text);
    final abw = double.tryParse(_currentAbwCtrl.text);
    final feedRate = double.tryParse(_feedingRateCtrl.text);
    if (stocked != null &&
        surv != null &&
        abw != null &&
        feedRate != null &&
        stocked > 0 &&
        surv >= 0 &&
        surv <= 100 &&
        abw > 0 &&
        feedRate >= 0 &&
        feedRate <= 100) {
      return (stocked * (surv / 100.0) * abw * (feedRate / 100.0)) / 1000.0;
    }
    return null;
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged(_calculateDFR());
  }

  @override
  void initState() {
    super.initState();
    _stockedCtrl.addListener(_onChanged);
    _survivalCtrl.addListener(_onChanged);
    _currentAbwCtrl.addListener(_onChanged);
    _feedingRateCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _stockedCtrl.dispose();
    _survivalCtrl.dispose();
    _currentAbwCtrl.dispose();
    _feedingRateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PondStatTextField(
          controller: _stockedCtrl,
          label: "Total fish stocked",
          hint: "e.g., 10000",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _survivalCtrl,
          label: "Estimated survival rate (%)",
          hint: "e.g., 80",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _currentAbwCtrl,
          label: "Current ABW (g)",
          hint: "e.g., 15",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _feedingRateCtrl,
          label: "Feeding rate (%)",
          hint: "e.g., 5",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 24),
        CalculatedResultBox(
          title: "Calculated DFR:",
          value: _calculateDFR(),
          unit: "kg/day",
          color: Colors.brown,
        ),
      ],
    );
  }
}
