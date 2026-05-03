import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/monitoring/presentation/growth_tab.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/presentation/record_growth_sheet.dart';
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
      builder: (sheetContext) => RecordGrowthSheet(
        species: widget.species,
        onSave:
            ({
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
                  .where(
                    'timestamp',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(sixDaysAgo),
                  )
                  .get();

              if (snapshot.docs.isNotEmpty) {
                throw Exception(
                  "You have already recorded $label within the last 7 days.",
                );
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Delete Sampling?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                "Are you sure you want to delete this sampling data? This action cannot be undone.",
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(context),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setStateDialog(() => isDeleting = true);
                          final user = FirebaseAuth.instance.currentUser;
                          final batch = FirebaseFirestore.instance.batch();

                          final docIds = [
                            m.abwDocId,
                            m.adgDocId,
                            m.dfrDocId,
                            m.fcrDocId,
                          ];
                          for (final docId in docIds) {
                            if (docId != null) {
                              final docRef = FirestoreHelper
                                  .measurementsCollection
                                  .doc(docId);
                              final docSnap = await docRef.get();
                              if (docSnap.exists) {
                                final historyRef = FirestoreHelper
                                    .measurementHistoryCollection
                                    .doc();
                                final data =
                                    docSnap.data() as Map<String, dynamic>;
                                batch.set(historyRef, {
                                  'pondId': widget.pondId,
                                  'measurementId': docId,
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
                            SnackbarHelper.show(
                              context,
                              "Error deleting: $e",
                              backgroundColor: Colors.red,
                            );
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.red,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Delete",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditGrowthDialog(GrowthMetrics m) {
    if (m.abwDocId == null &&
        m.adgDocId == null &&
        m.dfrDocId == null &&
        m.fcrDocId == null) {
      return;
    }

    final abwController = TextEditingController(text: m.abw.toString());
    final adgController = TextEditingController(text: m.adg.toString());
    final dfrController = TextEditingController(text: m.dfr.toString());
    final fcrController = TextEditingController(text: m.fcr.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            "Edit Sampling",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (m.abwDocId != null)
                  TextField(
                    controller: abwController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "ABW (g/pcs)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (m.abwDocId != null) const SizedBox(height: 16),
                if (m.adgDocId != null)
                  TextField(
                    controller: adgController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "ADG (g/day)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (m.adgDocId != null) const SizedBox(height: 16),
                if (m.dfrDocId != null)
                  TextField(
                    controller: dfrController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "DFR (%)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (m.dfrDocId != null) const SizedBox(height: 16),
                if (m.fcrDocId != null)
                  TextField(
                    controller: fcrController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: "FCR",
                      border: OutlineInputBorder(),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newAbw = double.tryParse(abwController.text);
                final newAdg = double.tryParse(adgController.text);
                final newDfr = double.tryParse(dfrController.text);
                final newFcr = double.tryParse(fcrController.text);

                if ((m.abwDocId != null && newAbw == null) ||
                    (m.adgDocId != null && newAdg == null) ||
                    (m.dfrDocId != null && newDfr == null) ||
                    (m.fcrDocId != null && newFcr == null)) {
                  SnackbarHelper.show(context, "Please enter valid numbers");
                  return;
                }

                final user = FirebaseAuth.instance.currentUser;
                final batch = FirebaseFirestore.instance.batch();

                Future<void> queueUpdate(
                  String? docId,
                  double newValue,
                  double oldValue,
                ) async {
                  if (docId == null || newValue == oldValue) return;
                  final docRef = FirestoreHelper.measurementsCollection.doc(
                    docId,
                  );
                  final docSnap = await docRef.get();
                  if (docSnap.exists) {
                    final data = docSnap.data() as Map<String, dynamic>;
                    batch.update(docRef, {
                      'value': newValue,
                      'editedAt': FieldValue.serverTimestamp(),
                      'editedBy': user?.uid,
                      'editorName': user?.displayName,
                    });
                    final historyRef = FirestoreHelper
                        .measurementHistoryCollection
                        .doc();
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

                await queueUpdate(m.abwDocId, newAbw ?? 0, m.abw);
                await queueUpdate(m.adgDocId, newAdg ?? 0, m.adg);
                await queueUpdate(m.dfrDocId, newDfr ?? 0, m.dfr);
                await queueUpdate(m.fcrDocId, newFcr ?? 0, m.fcr);

                try {
                  await batch.commit();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  setState(() => _refreshKey++);
                  SnackbarHelper.show(
                    context,
                    "Sampling updated",
                    backgroundColor: Colors.green,
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  SnackbarHelper.show(
                    context,
                    "Error updating: $e",
                    backgroundColor: Colors.red,
                  );
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
