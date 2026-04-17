import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'monitoring_parameters.dart';
import '../utility/helpers.dart';
import '../repositories/monitoring_repository.dart';
import '../widgets/pondstat_text_field.dart';
import '../widgets/primary_button.dart';

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
  }) onSave;

  const RecordDataSheet({
    super.key,
    required this.tabIndex,
    required this.onSave,
    required this.species,
  });

  @override
  State<RecordDataSheet> createState() => _RecordDataSheetState();
}

class _RecordDataSheetState extends State<RecordDataSheet> {
  ParameterItem? selectedParameter;
  String? selectedDocId;
  TimeOfDay selectedTime = TimeOfDay.now();

  final List<String> points = const ['A', 'B', 'C', 'D'];
  late final Map<String, TextEditingController> valueControllers;
  late final Map<String, FocusNode> focusNodes;

  bool _isSaving = false;
  final MonitoringRepository _repository = MonitoringRepository();

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color textDark = const Color(0xFF1E293B);
  final Color textMuted = const Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    valueControllers = {for (var p in points) p: TextEditingController()};
    focusNodes = {for (var p in points) p: FocusNode()};

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
    super.dispose();
  }

  // --- Logic ---

  void _processAndSaveForm() async {
    if (selectedParameter == null || _isSaving) return;

    double sum = 0;
    int count = 0;
    Map<String, double> pointValues = {};

    for (var p in points) {
      final textVal = valueControllers[p]!.text.trim();
      if (textVal.isNotEmpty) {
        final val = double.tryParse(textVal);

        if (val == null && selectedParameter!.keyboardType != TextInputType.text) {
          SnackbarHelper.show(context, "Point $p has an invalid number", backgroundColor: Colors.red);
          return;
        }

        if (val != null) {
          if (selectedParameter!.minVal != null && val < selectedParameter!.minVal!) {
            SnackbarHelper.show(context, "Point $p is below the minimum (${selectedParameter!.minVal})", backgroundColor: Colors.red);
            focusNodes[p]?.requestFocus();
            return;
          }
          if (selectedParameter!.maxVal != null && val > selectedParameter!.maxVal!) {
            SnackbarHelper.show(context, "Point $p is above the maximum (${selectedParameter!.maxVal})", backgroundColor: Colors.red);
            focusNodes[p]?.requestFocus();
            return;
          }
          sum += val;
          count++;
          pointValues[p] = val;
        }
      }
    }

    if (count == 0) {
      SnackbarHelper.show(context, "Please enter at least one valid value", backgroundColor: Colors.orange.shade700);
      return;
    }

    setState(() => _isSaving = true);
    double avg = double.parse((sum / count).toStringAsFixed(2));
    String type = ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    try {
      await widget.onSave(
        label: selectedParameter!.label,
        unit: selectedParameter!.unit,
        timeString: selectedTime.format(context),
        averageValue: avg,
        type: type,
        pointValues: pointValues,
      );

      HapticFeedback.heavyImpact();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, "Failed to save: $e", backgroundColor: Colors.redAccent);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showCreateParameterDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("New Parameter", style: TextStyle(fontWeight: FontWeight.w900)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                String type = ['daily', 'weekly', 'biweekly'][widget.tabIndex];
                await _repository.addCustomParameter(
                  label: nameController.text.trim(),
                  unit: unitController.text.trim(),
                  type: type,
                );
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Create", style: TextStyle(fontWeight: FontWeight.bold)),
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
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Colors.red)),
            const SizedBox(width: 12),
            const Text("Delete Parameter", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Text("Delete '${selectedParameter!.label}'? This will remove it for everyone.", style: TextStyle(color: textMuted, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () async {
              final idToDelete = selectedDocId!;
              await _repository.deleteCustomParameter(idToDelete);
              if (context.mounted) {
                Navigator.pop(context);
                setState(() { selectedParameter = null; selectedDocId = null; });
                SnackbarHelper.show(context, "Parameter deleted", backgroundColor: Colors.grey.shade800);
              }
            },
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
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
        setState(() { selectedParameter = param; selectedDocId = docId; });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) focusNodes['A']?.requestFocus();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [param.color.withValues(alpha: 0.85), param.color], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: param.color.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Icon(param.icon, color: Colors.white, size: 20)),
            Text(param.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.2, height: 1.1), overflow: TextOverflow.ellipsis, maxLines: 2),
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
    List<ParameterItem> hardcodedParams = MonitoringParameters.getParametersByIndex(widget.tabIndex, widget.species);
    String type = ['daily', 'weekly', 'biweekly'][widget.tabIndex];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('pondstat-app-v1').doc('pondstat-app-v1').collection('custom_parameters').where('type', isEqualTo: type).snapshots(),
      builder: (context, snapshot) {
        List<Widget> gridItems = hardcodedParams.map((p) => _buildParamTile(param: p)).toList();
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            gridItems.add(_buildParamTile(param: ParameterItem(label: data['label'], unit: data['unit'] ?? '', icon: Icons.dashboard_customize_rounded, color: Colors.blueGrey), docId: doc.id));
          }
        }
        gridItems.add(_buildAddNewButton());
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.95),
          itemCount: gridItems.length,
          itemBuilder: (context, i) => gridItems[i],
        );
      },
    );
  }

  Widget _buildInputForm() {
    final bool hasRange = selectedParameter!.minVal != null && selectedParameter!.maxVal != null;
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
                  Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)), child: Icon(selectedParameter!.icon, color: themeColor, size: 28)),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("RECORDING", style: TextStyle(color: themeColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    Text(selectedParameter!.label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: textDark, letterSpacing: -0.5), overflow: TextOverflow.ellipsis),
                  ])),
                ],
              ),
            ),
            if (selectedDocId != null) IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20)), onPressed: _confirmDeleteParameter),
          ],
        ),
        const SizedBox(height: 28),
        _buildTimePickerCard(themeColor),
        const SizedBox(height: 32),
        _buildDataPointsHeader(hasRange, themeColor),
        const SizedBox(height: 16),
        _buildDataPointInputs(themeColor),
        const SizedBox(height: 32),
        
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: themeColor),
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
        final picked = await showTimePicker(context: context, initialTime: selectedTime);
        if (picked != null) { HapticFeedback.selectionClick(); setState(() => selectedTime = picked); }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.grey.shade100)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: Icon(Icons.access_time_filled_rounded, color: textMuted, size: 18)),
              const SizedBox(width: 16),
              Text(selectedTime.format(context), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark)),
            ]),
            Text("Edit", style: TextStyle(color: themeColor, fontWeight: FontWeight.w800)),
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
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Data Points", style: TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 18)),
          if (hasRange) ...[
            const SizedBox(height: 4),
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text("Safe Range: ${selectedParameter!.minVal} - ${selectedParameter!.maxVal}", style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
          ] else if (selectedParameter!.minVal != null) ...[
            const SizedBox(height: 4),
            Text("Minimum: ${selectedParameter!.minVal}", style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ]),
        if (selectedParameter!.unit.isNotEmpty) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: themeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(selectedParameter!.unit, style: TextStyle(color: themeColor, fontWeight: FontWeight.w900, fontSize: 12))),
      ],
    );
  }

  Widget _buildDataPointInputs(Color themeColor) {
    return Row(
      children: points.map((p) {
        final isLast = p == 'D';
        final nextNode = isLast ? null : focusNodes[points[points.indexOf(p) + 1]];
        final bool isFocused = focusNodes[p]?.hasFocus ?? false;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(color: isFocused ? Colors.white : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: isFocused ? themeColor : Colors.transparent, width: isFocused ? 2 : 0), boxShadow: isFocused ? [BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))] : []),
              child: TextField(
                controller: valueControllers[p],
                focusNode: focusNodes[p],
                keyboardType: selectedParameter!.keyboardType,
                textInputAction: isLast ? TextInputAction.done : TextInputAction.next,
                onSubmitted: (_) {
                  if (!isLast) {
                    FocusScope.of(context).requestFocus(nextNode);
                  } else {
                    FocusScope.of(context).unfocus();
                  }
                },
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: textDark),
                decoration: InputDecoration(
                  labelText: "Pt $p",
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  labelStyle: TextStyle(color: isFocused ? themeColor : Colors.grey.shade500, fontWeight: FontWeight.w800, fontSize: 14),
                  hintText: selectedParameter!.hint.isEmpty ? '' : selectedParameter!.hint.split(' ').last,
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w600, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(top: 8, bottom: 12),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      padding: EdgeInsets.only(top: 12, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 48, height: 5, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
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
        if (selectedParameter != null) IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF1E293B))), onPressed: () { HapticFeedback.selectionClick(); setState(() { selectedParameter = null; selectedDocId = null; }); }),
        Expanded(child: Text(selectedParameter == null ? "Select Parameter" : "Enter Data", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5))),
        IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B))), onPressed: () => Navigator.pop(context)),
      ],
    );
  }

  Widget _buildContentSwitcher() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(animation), child: child)),
      child: selectedParameter == null ? KeyedSubtree(key: const ValueKey('grid'), child: _buildParameterGrid()) : KeyedSubtree(key: const ValueKey('form'), child: _buildInputForm()),
    );
  }
}
