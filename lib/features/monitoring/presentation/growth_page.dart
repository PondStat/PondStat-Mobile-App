import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/monitoring/presentation/growth_tab.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/features/monitoring/presentation/record_growth_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_growth_sheet.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class GrowthPage extends ConsumerStatefulWidget {
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
  ConsumerState<GrowthPage> createState() => _GrowthPageState();
}

class _GrowthPageState extends ConsumerState<GrowthPage> {
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
              try {
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

                await ref.read(monitoringRepositoryProvider).saveMeasurement(
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
              } catch (e) {
                if (!sheetContext.mounted) return;
                SnackbarHelper.show(
                  sheetContext,
                  e.toString().replaceAll("Exception: ", ""),
                  backgroundColor: Colors.redAccent,
                );
              }
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
            return PopScope(
              canPop: !isDeleting,
              child: AlertDialog(
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

                            try {
                              await GrowthRepository.deleteGrowthSampling(
                                m,
                                user,
                                widget.pondId,
                              );
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
              ),
            );
          },
        );
      },
    );
  }

  void _showEditGrowthSheet(GrowthMetrics m) {
    if (m.abwDocId == null &&
        m.adgDocId == null &&
        m.dfrDocId == null &&
        m.fcrDocId == null) {
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EditGrowthSheet(
        metrics: m,
        pondId: widget.pondId,
        onSave: () {
          setState(() => _refreshKey++);
          SnackbarHelper.show(
            context,
            "Sampling updated",
            backgroundColor: Colors.green,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GrowthTab(
        key: ValueKey(_refreshKey),
        pondId: widget.pondId,
        canEdit: widget.canEdit,
        onEdit: _showEditGrowthSheet,
        onDelete: _confirmDeleteGrowth,
      ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              heroTag: 'growth_fab',
              onPressed: () => _showRecordGrowth(),
              backgroundColor: colorScheme.primary,
              icon: Icon(Icons.add_rounded, color: colorScheme.onPrimary),
              label: Text(
                "Record Sampling",
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            )
          : null,
    );
  }
}
