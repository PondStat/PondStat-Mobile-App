import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/monitoring/presentation/growth_tab.dart';
import 'package:pondstat/core/widgets/destructive_dialog.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/presentation/record_growth_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_growth_sheet.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';


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
                final snapshot = await ref.read(monitoringRepositoryProvider).measurementsCollection
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
                SnackbarHelper.showSuccess(
                  sheetContext,
                  "Growth sampling recorded",
                );
              } catch (e) {
                if (!sheetContext.mounted) return;
                SnackbarHelper.showError(
                  sheetContext,
                  e.toString().replaceAll("Exception: ", ""),
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
      builder: (context) => DestructiveDialog(
        title: "Delete Sampling?",
        content: "Are you sure you want to delete this sampling data? This action cannot be undone.",
        onConfirm: () async {
          final user = FirebaseAuth.instance.currentUser;
          await ref.read(growthRepositoryProvider).deleteGrowthSampling(
            m,
            user,
            widget.pondId,
          );
          HapticFeedback.heavyImpact();
          if (context.mounted) {
            setState(() => _refreshKey++);
            SnackbarHelper.showInfo(context, "Sampling deleted");
          }
        },
      ),
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
          SnackbarHelper.showSuccess(context, "Sampling updated");
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
