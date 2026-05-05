import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/presentation/growth_data_service.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class EditGrowthSheet extends StatefulWidget {
  final GrowthMetrics metrics;
  final String pondId;
  final VoidCallback onSave;

  const EditGrowthSheet({
    super.key,
    required this.metrics,
    required this.pondId,
    required this.onSave,
  });

  @override
  State<EditGrowthSheet> createState() => _EditGrowthSheetState();
}

class _EditGrowthSheetState extends State<EditGrowthSheet> {
  late final TextEditingController abwController;
  late final TextEditingController adgController;
  late final TextEditingController dfrController;
  late final TextEditingController fcrController;

  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    abwController = TextEditingController(text: widget.metrics.abw.toString());
    adgController = TextEditingController(text: widget.metrics.adg.toString());
    dfrController = TextEditingController(text: widget.metrics.dfr.toString());
    fcrController = TextEditingController(text: widget.metrics.fcr.toString());
  }

  @override
  void dispose() {
    abwController.dispose();
    adgController.dispose();
    dfrController.dispose();
    fcrController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final newAbw = double.tryParse(abwController.text);
    final newAdg = double.tryParse(adgController.text);
    final newDfr = double.tryParse(dfrController.text);
    final newFcr = double.tryParse(fcrController.text);

    if (newAbw == null || newAdg == null || newDfr == null || newFcr == null) {
      SnackbarHelper.show(context, "Please enter valid numbers");
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final batch = FirebaseFirestore.instance.batch();

      Future<void> queueUpdate(
        String? docId,
        double newValue,
        double oldValue,
      ) async {
        if (docId == null || newValue == oldValue) return;
        final docRef = FirestoreHelper.measurementsCollection.doc(docId);
        final docSnap = await docRef.get();
        if (docSnap.exists) {
          final data = docSnap.data() as Map<String, dynamic>;
          batch.update(docRef, {
            'value': newValue,
            'editedAt': FieldValue.serverTimestamp(),
            'editedBy': user?.uid,
            'editorName': user?.displayName,
          });
          final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
          batch.set(historyRef, {
            'pondId': widget.pondId,
            'measurementId': docId,
            'parameter': data['parameter'],
            'action': 'update',
            'editedAt': FieldValue.serverTimestamp(),
            'editedBy': user?.uid,
            'editorName': user?.displayName ?? 'Unknown',
            'before': {'value': data['value']},
            'after': {'value': newValue},
          });
        }
      }

      await queueUpdate(widget.metrics.abwDocId, newAbw, widget.metrics.abw);
      await queueUpdate(widget.metrics.adgDocId, newAdg, widget.metrics.adg);
      await queueUpdate(widget.metrics.dfrDocId, newDfr, widget.metrics.dfr);
      await queueUpdate(widget.metrics.fcrDocId, newFcr, widget.metrics.fcr);

      await batch.commit();

      if (!mounted) return;
      widget.onSave();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        "Error updating: $e",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _numberValidator(String? value) {
    if (value == null || value.isEmpty) return "Required";
    final number = double.tryParse(value);
    if (number == null) return "Invalid number";
    if (number < 0) return "Cannot be negative";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.metrics;
    final dateStr = DateFormat('MMM dd, yyyy').format(m.date);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Edit Sampling",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Week ${m.weekNumber} • $dateStr",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (m.abwDocId != null)
                PondStatTextField(
                  controller: abwController,
                  label: "ABW (g/pcs)",
                  hint: "0.0",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
                  textInputAction: TextInputAction.next,
                ),
              if (m.abwDocId != null) const SizedBox(height: 16),

              if (m.adgDocId != null)
                PondStatTextField(
                  controller: adgController,
                  label: "ADG (g/day)",
                  hint: "0.0",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
                  textInputAction: TextInputAction.next,
                ),
              if (m.adgDocId != null) const SizedBox(height: 16),

              if (m.dfrDocId != null)
                PondStatTextField(
                  controller: dfrController,
                  label: "DFR (%)",
                  hint: "0.0",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
                  textInputAction: TextInputAction.next,
                ),
              if (m.dfrDocId != null) const SizedBox(height: 16),

              if (m.fcrDocId != null)
                PondStatTextField(
                  controller: fcrController,
                  label: "FCR",
                  hint: "0.0",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
                  textInputAction: TextInputAction.done,
                ),
              if (m.fcrDocId != null) const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  text: "Save Changes",
                  isLoading: _isSaving,
                  onPressed: _saveChanges,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
