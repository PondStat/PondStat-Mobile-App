import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/monitoring/presentation/growth_tab.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/presentation/record_data_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/growth_data_service.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class GrowthPage extends StatefulWidget {
  final String pondId;
  final String pondName;
  final String species;
  final bool canEdit;

  const GrowthPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.canEdit,
  });

  @override
  State<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends State<GrowthPage> {
  int _refreshKey = 0;

  void _showRecordGrowth() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => RecordDataSheet(
        tabIndex: 1,
        species: widget.species,
        customParams: MonitoringParameters.samplingParameters,
        customType: 'growth',
        onSave: ({
          required String label,
          required String unit,
          required String timeString,
          required double averageValue,
          required String type,
          required Map<String, double> pointValues,
          required Map<String, List<double>> replicateValues,
          String? notes,
        }) async {
          final now = DateTime.now();
          final sixDaysAgo = now.subtract(const Duration(days: 6));
          final snapshot = await FirestoreHelper.measurementsCollection
              .where('pondId', isEqualTo: widget.pondId)
              .where('parameter', isEqualTo: label)
              .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(sixDaysAgo))
              .get();

          if (snapshot.docs.isNotEmpty) {
            throw Exception("You have already recorded $label within the last 7 days.");
          }

          final repository = MonitoringRepository();
          await repository.saveMeasurement(
            pondId: widget.pondId,
            label: label,
            unit: unit,
            timeString: timeString,
            averageValue: averageValue,
            type: type,
            pointValues: pointValues,
            replicateValues: replicateValues,
            selectedDay: now,
            notes: notes,
          );
          if (!sheetContext.mounted) return;
          setState(() {
            _refreshKey++;
          });
          SnackbarHelper.show(
            sheetContext,
            "Growth sampling recorded",
            backgroundColor: Colors.green,
          );
        },
      ),
    );
  }

  void _confirmDeleteGrowth(GrowthMetrics m) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text("Delete Sampling?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
              content: const Text("Are you sure you want to delete this sampling data? This action cannot be undone."),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, elevation: 0),
                  onPressed: isDeleting ? null : () async {
                    setStateDialog(() => isDeleting = true);
                    final user = FirebaseAuth.instance.currentUser;
                    final batch = FirebaseFirestore.instance.batch();
                    
                    if (m.weightDocId != null) {
                      final docRef = FirestoreHelper.measurementsCollection.doc(m.weightDocId);
                      final docSnap = await docRef.get();
                      if (docSnap.exists) {
                         final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
                         final data = docSnap.data() as Map<String, dynamic>;
                         batch.set(historyRef, {
                            'pondId': widget.pondId,
                            'measurementId': m.weightDocId,
                            'parameter': data['parameter'],
                            'action': 'delete',
                            'editedAt': FieldValue.serverTimestamp(),
                            'editedBy': user?.uid,
                            'editorName': user?.displayName ?? 'Unknown',
                            'before': {'value': data['value']},
                            'after': null,
                          });
                         batch.delete(docRef);
                      }
                    }
                    if (m.countDocId != null) {
                      final docRef = FirestoreHelper.measurementsCollection.doc(m.countDocId);
                      final docSnap = await docRef.get();
                      if (docSnap.exists) {
                         final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
                         final data = docSnap.data() as Map<String, dynamic>;
                         batch.set(historyRef, {
                            'pondId': widget.pondId,
                            'measurementId': m.countDocId,
                            'parameter': data['parameter'],
                            'action': 'delete',
                            'editedAt': FieldValue.serverTimestamp(),
                            'editedBy': user?.uid,
                            'editorName': user?.displayName ?? 'Unknown',
                            'before': {'value': data['value']},
                            'after': null,
                          });
                         batch.delete(docRef);
                      }
                    }

                    try {
                      await batch.commit();
                      HapticFeedback.heavyImpact();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      setState(() => _refreshKey++);
                      SnackbarHelper.show(context, "Sampling deleted");
                    } catch (e) {
                      if (!context.mounted) return;
                      setStateDialog(() => isDeleting = false);
                      SnackbarHelper.show(context, "Error deleting: $e", backgroundColor: Colors.red);
                    }
                  },
                  child: isDeleting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2)) : const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  void _showEditGrowthDialog(GrowthMetrics m) {
    if (m.weightDocId == null || m.countDocId == null) return;
    
    final weightController = TextEditingController(text: m.totalWeight.toString());
    final countController = TextEditingController(text: m.sampleCount.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Edit Sampling", style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: "Total Weight (g)", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Sample Count (pcs)", border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              onPressed: () async {
                final newWeight = double.tryParse(weightController.text);
                final newCount = double.tryParse(countController.text);

                if (newWeight == null || newCount == null) {
                  SnackbarHelper.show(context, "Please enter valid numbers");
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                final batch = FirebaseFirestore.instance.batch();

                // Update Weight
                final wDocRef = FirestoreHelper.measurementsCollection.doc(m.weightDocId);
                final wDocSnap = await wDocRef.get();
                if (wDocSnap.exists) {
                   final data = wDocSnap.data() as Map<String, dynamic>;
                   batch.update(wDocRef, {'value': newWeight, 'editedAt': FieldValue.serverTimestamp(), 'editedBy': user?.uid, 'editorName': user?.displayName});
                   final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
                   batch.set(historyRef, {
                      'pondId': widget.pondId,
                      'measurementId': m.weightDocId,
                      'parameter': data['parameter'],
                      'action': 'update',
                      'editedAt': FieldValue.serverTimestamp(),
                      'editedBy': user?.uid,
                      'editorName': user?.displayName ?? 'Unknown',
                      'before': {'value': data['value']},
                      'after': {'value': newWeight},
                   });
                }

                // Update Count
                final cDocRef = FirestoreHelper.measurementsCollection.doc(m.countDocId);
                final cDocSnap = await cDocRef.get();
                if (cDocSnap.exists) {
                   final data = cDocSnap.data() as Map<String, dynamic>;
                   batch.update(cDocRef, {'value': newCount, 'editedAt': FieldValue.serverTimestamp(), 'editedBy': user?.uid, 'editorName': user?.displayName});
                   final historyRef = FirestoreHelper.measurementHistoryCollection.doc();
                   batch.set(historyRef, {
                      'pondId': widget.pondId,
                      'measurementId': m.countDocId,
                      'parameter': data['parameter'],
                      'action': 'update',
                      'editedAt': FieldValue.serverTimestamp(),
                      'editedBy': user?.uid,
                      'editorName': user?.displayName ?? 'Unknown',
                      'before': {'value': data['value']},
                      'after': {'value': newCount},
                   });
                }

                try {
                  await batch.commit();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() => _refreshKey++);
                  SnackbarHelper.show(context, "Sampling updated", backgroundColor: Colors.green);
                } catch (e) {
                  if (!context.mounted) return;
                  SnackbarHelper.show(context, "Error updating: $e", backgroundColor: Colors.red);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GrowthTab(
        key: ValueKey(_refreshKey),
        pondId: widget.pondId,
        canEdit: widget.canEdit,
        onEdit: _showEditGrowthDialog,
        onDelete: _confirmDeleteGrowth,
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              heroTag: 'growth_fab',
              onPressed: () => _showRecordGrowth(),
              backgroundColor: Colors.indigo.shade400,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Record Sampling",
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}
