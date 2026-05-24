import 'package:flutter/material.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/calculated_result_box.dart';

class FcrForm extends StatefulWidget {
  final void Function(double? calculatedValue) onChanged;

  const FcrForm({super.key, required this.onChanged});

  @override
  State<FcrForm> createState() => _FcrFormState();
}

class _FcrFormState extends State<FcrForm> {
  final TextEditingController _feedCtrl = TextEditingController();
  final TextEditingController _weightGainedCtrl = TextEditingController();

  double? _calculateFCR() {
    final feed = double.tryParse(_feedCtrl.text);
    final gained = double.tryParse(_weightGainedCtrl.text);
    if (feed != null && gained != null && feed > 0 && gained > 0) {
      return feed / gained;
    }
    return null;
  }

  void _onChanged() {
    setState(() {});
    widget.onChanged(_calculateFCR());
  }

  @override
  void initState() {
    super.initState();
    _feedCtrl.addListener(_onChanged);
    _weightGainedCtrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _feedCtrl.dispose();
    _weightGainedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PondStatTextField(
          controller: _feedCtrl,
          label: "Total weight of feed given (g)",
          hint: "e.g., 2000",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 16),
        PondStatTextField(
          controller: _weightGainedCtrl,
          label: "Total weight gained by fish (g)",
          hint: "e.g., 1500",
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 24),
        CalculatedResultBox(
          title: "Calculated FCR:",
          value: _calculateFCR(),
          unit: "",
          color: Colors.orange,
        ),
      ],
    );
  }
}
