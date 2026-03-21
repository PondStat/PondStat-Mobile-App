import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'monitoring_parameters.dart';
import '../utility/helpers.dart';
import '../firebase/firestore_helper.dart';

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
  String? selectedDocId; // Track the Firestore ID for deletion
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

  // --- Logic: Saving Measurements ---
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

  // --- Logic: Custom Parameters ---
  void _showCreateParameterDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("New Parameter"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Parameter Name"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: unitController,
              decoration: const InputDecoration(labelText: "Unit (e.g., ppm, °C)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                String type = ['daily', 'weekly', 'biweekly'][widget.tabIndex];
                await FirestoreHelper.customParametersCollection.add({
                  'label': nameController.text.trim(),
                  'unit': unitController.text.trim(),
                  'type': type,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Create"),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Delete Parameter"),
          ],
        ),
        content: Text("Delete '${selectedParameter!.label}'? This will remove it for everyone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50, 
              foregroundColor: Colors.red,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              final idToDelete = selectedDocId;
              
              // Go back to the parameter grid first
              setState(() {
                selectedParameter = null;
                selectedDocId = null;
              });

              await FirestoreHelper.customParametersCollection.doc(idToDelete).delete();
              if (mounted) SnackbarHelper.show(context, "Parameter deleted");
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // --- UI Builders ---
  Widget _buildParamTile({required ParameterItem param, String? docId}) {
    return InkWell(
      onTap: () => setState(() {
        selectedParameter = param;
        selectedDocId = docId; // Store the ID when selected
      }),
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
            Icon(param.icon, color: param.color, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                param.label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewButton() {
    return InkWell(
      onTap: _showCreateParameterDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF0077C2), width: 1.5),
          borderRadius: BorderRadius.circular(12),
          color: Colors.blue.shade50,
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Color(0xFF0077C2)),
              SizedBox(width: 4),
              Text(
                "Add New", 
                style: TextStyle(color: Color(0xFF0077C2), fontWeight: FontWeight.bold)
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParameterGrid() {
    List<ParameterItem> hardcodedParams = MonitoringParameters.getParametersByIndex(widget.tabIndex);
    String type = ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.customParametersCollection
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        List<Widget> gridItems = hardcodedParams.map((p) => _buildParamTile(param: p)).toList();

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            gridItems.add(_buildParamTile(
              param: ParameterItem(
                label: data['label'],
                unit: data['unit'] ?? '',
                icon: Icons.add_chart,
                color: Colors.blueGrey,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              docId: doc.id,
            ));
          }
        }

        gridItems.add(_buildAddNewButton());

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: gridItems.length,
          itemBuilder: (context, i) => gridItems[i],
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
        // Header with Delete Button for custom parameters
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recording ${selectedParameter!.label}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (selectedDocId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: _confirmDeleteParameter,
                tooltip: "Delete this parameter",
              ),
          ],
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(context: context, initialTime: selectedTime);
            if (picked != null) setState(() => selectedTime = picked);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(
                      "Time: ${selectedTime.format(context)}", 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                const Text("Change", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Values per point ${selectedParameter!.unit.isNotEmpty ? '(${selectedParameter!.unit})' : ''}:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (rangeText.isNotEmpty)
              Text(rangeText, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: points.map((p) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: valueControllers[p],
                keyboardType: selectedParameter!.keyboardType,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: "Pt $p",
                  hintText: selectedParameter!.hint.isEmpty ? '' : selectedParameter!.hint.split(' ').last,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: const Color(0xFF0077C2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _processAndSaveForm,
          child: const Text(
            "Save Measurement", 
            style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)
          ),
        )
      ],
    );
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
                    onPressed: () => setState(() {
                      selectedParameter = null;
                      selectedDocId = null; // Clear ID on back
                    }),
                  ),
                Expanded(
                  child: Text(
                    selectedParameter == null ? "Select Parameter" : "Parameter Details",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey), 
                  onPressed: () => Navigator.pop(context)
                )
              ],
            ),
            const Divider(height: 24),
            if (selectedParameter == null) _buildParameterGrid() else _buildInputForm(),
          ],
        ),
      ),
    );
  }
}