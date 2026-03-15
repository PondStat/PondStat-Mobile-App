import 'package:flutter/material.dart';
import 'monitoring_parameters.dart';
import '../utility/helpers.dart';

class RecordDataSheet extends StatefulWidget {
  final int tabIndex;
  final Future<void> Function({
    required String label,
    required String unit,
    required String timeString,
    required double averageValue,
    required String type,
    required Map<String, double> pointValues,
  }) onSave;

  const RecordDataSheet({
    super.key,
    required this.tabIndex,
    required this.onSave,
  });

  @override
  State<RecordDataSheet> createState() => _RecordDataSheetState();
}

class _RecordDataSheetState extends State<RecordDataSheet> {
  ParameterItem? selectedParameter;
  TimeOfDay selectedTime = TimeOfDay.now();
  final List<String> points = const ['A', 'B', 'C', 'D'];
  late final Map<String, TextEditingController> valueControllers;

  @override
  void initState() {
    super.initState();
    valueControllers = {for (var p in points) p: TextEditingController()};
  }

  @override
  void dispose() {
    for (var controller in valueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _processAndSaveForm() {
    if (selectedParameter == null) return;
    
    double sum = 0;
    int count = 0;
    Map<String, double> pointValues = {};

    for (var p in points) {
      final textVal = valueControllers[p]!.text.trim();
      if (textVal.isNotEmpty) {
        final val = double.tryParse(textVal);

        if (val == null && selectedParameter!.keyboardType != TextInputType.text) {
          SnackbarHelper.show(context, "Point $p has an invalid number");
          return;
        }

        if (val != null) {
          if (selectedParameter!.minVal != null && val < selectedParameter!.minVal!) {
            SnackbarHelper.show(context, "Point $p is below the minimum (${selectedParameter!.minVal})");
            return;
          }
          if (selectedParameter!.maxVal != null && val > selectedParameter!.maxVal!) {
            SnackbarHelper.show(context, "Point $p is above the maximum (${selectedParameter!.maxVal})");
            return;
          }

          sum += val;
          count++;
          pointValues[p] = val;
        }
      }
    }

    if (count == 0) {
      SnackbarHelper.show(context, "Please enter at least one valid value");
      return;
    }

    double avg = double.parse((sum / count).toStringAsFixed(2));
    String type = ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    widget.onSave(
      label: selectedParameter!.label,
      unit: selectedParameter!.unit,
      timeString: selectedTime.format(context),
      averageValue: avg,
      type: type,
      pointValues: pointValues,
    );

    Navigator.pop(context);
    SnackbarHelper.show(context, "Saved ${selectedParameter!.label}: $avg ${selectedParameter!.unit}");
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (selectedParameter != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => setState(() => selectedParameter = null),
                  ),
                Expanded(
                  child: Text(
                    selectedParameter == null
                        ? "Select Parameter"
                        : "Record ${selectedParameter!.label}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(height: 24),
            if (selectedParameter == null)
              _buildParameterGrid()
            else
              _buildInputForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterGrid() {
    List<ParameterItem> parameters = MonitoringParameters.getParametersByIndex(widget.tabIndex);

    if (parameters.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No parameters for this tab."),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemCount: parameters.length,
      itemBuilder: (context, i) {
        final param = parameters[i];
        return InkWell(
          onTap: () => setState(() => selectedParameter = param),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  param.icon,
                  color: param.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    param.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputForm() {
    String rangeText = '';
    if (selectedParameter!.minVal != null && selectedParameter!.maxVal != null) {
      rangeText = 'Range: ${selectedParameter!.minVal} - ${selectedParameter!.maxVal}';
    } else if (selectedParameter!.minVal != null) {
      rangeText = 'Min: ${selectedParameter!.minVal}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: selectedTime,
            );
            if (picked != null) setState(() => selectedTime = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      "Time: ${selectedTime.format(context)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const Text(
                  "Change",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Enter values per point ${selectedParameter!.unit.isNotEmpty ? '(${selectedParameter!.unit})' : ''}:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (rangeText.isNotEmpty)
              Text(
                rangeText,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: points
              .map(
                (p) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: valueControllers[p],
                      keyboardType: selectedParameter!.keyboardType,
                      textAlign: TextAlign.center,
                      textInputAction: p == points.last
                          ? TextInputAction.done
                          : TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: "Pt $p",
                        hintText: selectedParameter!.hint.split(' ').last,
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF0077C2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _processAndSaveForm,
          child: const Text(
            "Save Measurement",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}