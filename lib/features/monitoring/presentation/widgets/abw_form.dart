import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/calculated_result_box.dart';
import 'package:pondstat/features/monitoring/utils/growth_calculators.dart';

class AbwForm extends StatefulWidget {
  final void Function(double? calculatedValue) onChanged;

  const AbwForm({super.key, required this.onChanged});

  @override
  State<AbwForm> createState() => _AbwFormState();
}

class _AbwFormState extends State<AbwForm> {
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _countCtrl = TextEditingController();

  double? _calculateABW() {
    return GrowthCalculators.calculateABW(
      weight: double.tryParse(_weightCtrl.text),
      count: double.tryParse(_countCtrl.text),
    );
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged(_calculateABW());
  }

  @override
  void initState() {
    super.initState();
    _weightCtrl.addListener(_onChanged);
    _countCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _countCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PondStatTextField(
          controller: _weightCtrl,
          label: "Total weight of sampled fish (g)",
          hint: "e.g., 500",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _countCtrl,
          label: "Number of fish sampled",
          hint: "e.g., 50",
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        CalculatedResultBox(
          title: "Calculated ABW:",
          value: _calculateABW(),
          unit: "g",
          color: Colors.green,
        ),
      ],
    );
  }
}
