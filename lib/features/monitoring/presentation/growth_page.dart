import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/presentation/growth_tab.dart';
import 'package:pondstat/core/widgets/destructive_dialog.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/presentation/record_growth_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_growth_sheet.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';


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

  final GlobalKey _growthListKey = GlobalKey();
  final GlobalKey _recordGrowthKey = GlobalKey();

  void _startTour() {
    final keys = [_growthListKey];
    if (widget.canEdit) {
      keys.add(_recordGrowthKey);
    }
    ShowcaseView.get().startShowCase(keys);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(onboardingTourProvider).hasSeenGrowth;
      if (!hasSeen) {
        _startTour();
        ref.read(onboardingTourProvider.notifier).markGrowthAsSeen();
      }
    });
  }

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

                final currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'A collaborator';
                try {
                  await ref.read(notificationsRepositoryProvider).notifyPondMembers(
                    pondId: widget.pondId,
                    title: 'Growth Sampling Recorded in ${widget.pondName}',
                    body: '$currentUserName recorded growth sampling ($label: $averageValue$unit).',
                  );
                } catch (e, stackTrace) {
                  ref.read(appLoggerProvider).error(
                    'Failed to send growth sampling notification',
                    error: e,
                    stackTrace: stackTrace,
                    tag: 'COLLABORATORS',
                  );
                }

                if (!sheetContext.mounted) return;
                setState(() {
                  _refreshKey++;
                });
                final connectivityResult = await Connectivity().checkConnectivity().timeout(
                  const Duration(seconds: 1),
                  onTimeout: () => [ConnectivityResult.none],
                );
                if (!sheetContext.mounted) return;
                if (connectivityResult.contains(ConnectivityResult.none)) {
                  SnackbarHelper.showSuccess(
                    sheetContext,
                    "Growth sampling saved locally (will sync when online)",
                  );
                } else {
                  SnackbarHelper.showSuccess(
                    sheetContext,
                    "Growth sampling recorded",
                  );
                }
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
        onSave: () async {
          setState(() => _refreshKey++);
          final connectivityResult = await Connectivity().checkConnectivity().timeout(
            const Duration(seconds: 1),
            onTimeout: () => [ConnectivityResult.none],
          );
          if (mounted) {
            if (connectivityResult.contains(ConnectivityResult.none)) {
              SnackbarHelper.showSuccess(context, "Sampling saved locally (will sync when online)");
            } else {
              SnackbarHelper.showSuccess(context, "Sampling updated");
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    ref.listen<int?>(tourTriggerProvider, (previous, next) {
      if (next == 3) {
        _startTour();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomShowcase(
        showcaseKey: _growthListKey,
        title: 'Growth Performance & Records',
        description: 'Track growth sampling indices like Average Body Weight (ABW), Average Daily Growth (ADG), Feed Conversion Ratio (FCR), and more over time.',
        child: GrowthTab(
          key: ValueKey(_refreshKey),
          pondId: widget.pondId,
          canEdit: widget.canEdit,
          onEdit: _showEditGrowthSheet,
          onDelete: _confirmDeleteGrowth,
        ),
      ),
      floatingActionButton: widget.canEdit
          ? CustomShowcase(
              showcaseKey: _recordGrowthKey,
              title: 'Record Sampling',
              description: 'Tap here to log a new periodic fish growth sampling session (ABW, replicates, etc.).',
              child: Semantics(
                label: "Record growth sampling data",
                button: true,
                child: FloatingActionButton.extended(
                  heroTag: 'growth_fab',
                  onPressed: () => _showRecordGrowth(),
                  backgroundColor: colorScheme.primary,
                  icon: Icon(Icons.add_rounded, color: colorScheme.onPrimary),
                  label: Text(
                    "Record Sampling",
                    style: TextStyle(color: colorScheme.onPrimary),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
