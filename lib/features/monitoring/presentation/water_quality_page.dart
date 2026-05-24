import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/measurement_list_view.dart';
import 'package:pondstat/features/monitoring/presentation/record_data_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_parameter_sheet.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/services/safety_service.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/features/notifications/data/notifications_repository.dart';
import 'package:pondstat/core/services/safety/alert_types.dart';
import 'package:pondstat/core/services/logging/logger_provider.dart';


class WaterQualityPage extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String species;
  final bool canEdit;
  final DateTime selectedDay;

  const WaterQualityPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.canEdit,
    required this.selectedDay,
  });

  @override
  ConsumerState<WaterQualityPage> createState() => _WaterQualityPageState();
}

class _WaterQualityPageState extends ConsumerState<WaterQualityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final GlobalKey _qualityTabsKey = GlobalKey();
  final GlobalKey _measurementsListKey = GlobalKey();
  final GlobalKey _recordParamsKey = GlobalKey();

  void _startTour() {
    final keys = [_qualityTabsKey, _measurementsListKey];
    if (widget.canEdit) {
      keys.add(_recordParamsKey);
    }
    ShowcaseView.get().startShowCase(keys);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(onboardingTourProvider).hasSeenParameter;
      if (!hasSeen) {
        _startTour();
        ref.read(onboardingTourProvider.notifier).markParameterAsSeen();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveData({
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
      final parameterItem = MonitoringParameters.getParameterByLabel(
        label,
        widget.species,
      );

      Map<String, dynamic>? alertMap;
      AlertPayload? alertPayload;
      if (parameterItem != null) {
        alertPayload = ref.read(safetyServiceProvider).getAlertPayload(
          parameter: parameterItem,
          value: averageValue,
          pondId: widget.pondId,
          pondName: widget.pondName,
        );
        if (alertPayload != null) {
          alertMap = {
            'title': alertPayload.title,
            'body': alertPayload.body,
            'tier': alertPayload.tier.name,
          };
        }
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
        selectedDay: widget.selectedDay,
        notes: notes,
        alert: alertMap,
      );

      final currentUserName = FirebaseAuth.instance.currentUser?.displayName ?? 'A collaborator';
      try {
        final hasAlert = alertPayload != null;
        await ref.read(notificationsRepositoryProvider).notifyPondMembers(
          pondId: widget.pondId,
          title: hasAlert 
              ? alertPayload.title 
              : 'New Parameter Recorded in ${widget.pondName}',
          body: hasAlert 
              ? alertPayload.body 
              : '$currentUserName recorded $label: $averageValue$unit.',
        );
      } catch (e, stackTrace) {
        ref.read(appLoggerProvider).error(
          'Failed to send parameter recording notification',
          error: e,
          stackTrace: stackTrace,
          tag: 'COLLABORATORS',
        );
      }

      if (parameterItem != null) {
        await ref.read(safetyServiceProvider).checkAndNotify(
          parameter: parameterItem,
          value: averageValue,
          pondId: widget.pondId,
          pondName: widget.pondName,
        );
      }

      if (mounted) {
        final connectivityResult = await Connectivity().checkConnectivity().timeout(
          const Duration(seconds: 1),
          onTimeout: () => [ConnectivityResult.none],
        );
        if (mounted) {
          if (connectivityResult.contains(ConnectivityResult.none)) {
            SnackbarHelper.showSuccess(context, "Data saved locally (will sync when online)");
          } else {
            SnackbarHelper.showSuccess(context, "Data recorded");
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Error: $e");
      }
    }
  }

  void _showAddDataOverlay() {
    if (!widget.canEdit) {
      SnackbarHelper.showInfo(context, 'Permissions required to add data.');
      return;
    }

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDataSheet(
        tabIndex: _tabController.index,
        onSave: _handleSaveData,
        species: widget.species,
        pondId: widget.pondId,
        selectedDay: widget.selectedDay,
      ),
    );
  }

  void _showEditDataDialog(List<DocumentSnapshot> docs) {
    if (!widget.canEdit) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditParameterSheet(
        docs: docs,
        pondId: widget.pondId,
        species: widget.species,
        repository: ref.read(monitoringRepositoryProvider),
        onSave: () {
          // Trigger a rebuild if necessary, or the stream will naturally update.
        },
      ),
    );
  }

  Widget _buildTabContent(String type, String dateKey, Color primaryColor) {
    return Column(
      children: [
        Expanded(
          child: MeasurementListView(
            pondId: widget.pondId,
            type: type,
            dateKey: dateKey,
            canEdit: widget.canEdit,
            onEdit: _showEditDataDialog,
            primaryBlue: primaryColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey =
        "${widget.selectedDay.year}-${widget.selectedDay.month}-${widget.selectedDay.day}";
    final primaryColor = Theme.of(context).colorScheme.primary;

    String fabLabel = "Record Daily";
    if (_tabController.index == 1) {
      fabLabel = "Record Weekly";
    } else if (_tabController.index == 2) {
      fabLabel = "Record Biweekly";
    }

    ref.listen<int?>(tourTriggerProvider, (previous, next) {
      if (next == 4) {
        _startTour();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          CustomShowcase(
            showcaseKey: _qualityTabsKey,
            title: 'Parameter Schedules',
            description: 'Switch between parameters grouped by sampling frequency: Daily (pH, Temp, DO), Weekly (Alkalinity, Salinity), or Biweekly.',
            child: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: TabBar(
                isScrollable: false,
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: primaryColor,
                tabs: const [
                  Tab(text: "Daily"),
                  Tab(text: "Weekly"),
                  Tab(text: "Biweekly"),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomShowcase(
              showcaseKey: _measurementsListKey,
              title: 'Water Quality Records',
              description: 'View recorded measurements for the selected day. Tap any card to edit details if permissions allow.',
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent('daily', dateKey, primaryColor),
                  _buildTabContent('weekly', dateKey, primaryColor),
                  _buildTabContent('biweekly', dateKey, primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: widget.canEdit
          ? CustomShowcase(
              showcaseKey: _recordParamsKey,
              title: 'Record Parameter Data',
              description: 'Tap here to log a new water quality parameter reading for the selected date.',
              child: Semantics(
                label: "Record water quality data",
                button: true,
                child: FloatingActionButton.extended(
                  heroTag: 'water_quality_fab',
                  onPressed: _showAddDataOverlay,
                  icon: const Icon(Icons.add),
                  label: Text(fabLabel),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          : null,
    );
  }
}
