import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/culture_progress_card.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_calendar.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/weather_overview_card.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/utils/responsive_helper.dart';

class OverviewTab extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String userRole;
  final String species;
  final DateTime createdAt;
  final int targetCulturePeriodDays;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;
  final VoidCallback onRecordParameters;
  final GlobalKey? profileKey;
  final GlobalKey? historyKey;
  final GlobalKey? chatKey;
  final GlobalKey? helpKey;

  const OverviewTab({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
    required this.species,
    required this.createdAt,
    required this.targetCulturePeriodDays,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
    required this.onRecordParameters,
    this.profileKey,
    this.historyKey,
    this.chatKey,
    this.helpKey,
  });

  @override
  ConsumerState<OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<OverviewTab> {
  final GlobalKey _progressCardKey = GlobalKey();
  final GlobalKey _calendarKey = GlobalKey();
  final GlobalKey _recordButtonKey = GlobalKey();

  void _startTour() {
    final keys = <GlobalKey>[];
    if (widget.historyKey != null) keys.add(widget.historyKey!);
    if (widget.chatKey != null) keys.add(widget.chatKey!);
    if (widget.helpKey != null) keys.add(widget.helpKey!);
    if (widget.profileKey != null) keys.add(widget.profileKey!);
    keys.addAll([
      _progressCardKey,
      _calendarKey,
    ]);
    if (widget.userRole == 'owner' || widget.userRole == 'editor') {
      keys.add(_recordButtonKey);
    }
    ShowcaseView.getNamed('pond_monitoring').startShowCase(keys);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(onboardingTourProvider).hasSeenOverview;
      if (!hasSeen) {
        _startTour();
        ref.read(onboardingTourProvider.notifier).markOverviewAsSeen();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(tourTriggerProvider, (previous, next) {
      if (next == 2) { // Overview is index 2
        _startTour();
      }
    });

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pondStream = ref.watch(pondRepositoryProvider).getPondStream(widget.pondId);

    return StreamBuilder<Pond>(
      stream: pondStream,
      builder: (context, snapshot) {
        final pond = snapshot.data;
        final lat = pond?.latitude;
        final lon = pond?.longitude;
        final canEdit = widget.userRole == 'owner' || widget.userRole == 'editor';

        final bool isWide = ResponsiveHelper.isWide(context);

        if (isWide) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [

                        CustomShowcase(
                          showcaseKey: _progressCardKey,
                          scope: 'pond_monitoring',
                          title: 'Culture Progress',
                          description: 'Track the current day of culture, target period, and overall progress metrics of this culture cycle.',
                          child: CultureProgressCard(
                            createdAt: widget.createdAt,
                            targetCulturePeriodDays: widget.targetCulturePeriodDays,
                          ),
                        ),
                        const SizedBox(height: 16),
                        WeatherOverviewCard(
                          pondId: widget.pondId,
                          pondName: widget.pondName,
                          latitude: lat,
                          longitude: lon,
                          canEdit: canEdit,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CustomShowcase(
                          showcaseKey: _calendarKey,
                          scope: 'pond_monitoring',
                          title: 'Monitoring Calendar',
                          description: 'Select a day to view historical records, trends, or log daily parameters.',
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainer
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: isDark
                                  ? null
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 24,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: MonitoringCalendar(
                              pondId: widget.pondId,
                              focusedDay: widget.focusedDay,
                              selectedDay: widget.selectedDay,
                              firstDay: widget.createdAt,
                              lastDay: widget.createdAt.add(Duration(days: widget.targetCulturePeriodDays)),
                              onDaySelected: widget.onDaySelected,
                              onPageChanged: widget.onPageChanged,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (widget.userRole == 'owner' || widget.userRole == 'editor')
                          CustomShowcase(
                            showcaseKey: _recordButtonKey,
                            scope: 'pond_monitoring',
                            title: 'Record Parameters',
                            description: 'Tap here to enter daily water quality data such as temperature, pH, and dissolved oxygen.',
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (widget.selectedDay == null) {
                                    SnackbarHelper.showInfo(context, 'Please select a day first on the calendar.');
                                    return;
                                  }
                                  widget.onRecordParameters();
                                },
                                icon: const Icon(Icons.water_drop_rounded),
                                label: const Text('Record Parameters'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              CustomShowcase(
                showcaseKey: _progressCardKey,
                scope: 'pond_monitoring',
                title: 'Culture Progress',
                description: 'Track the current day of culture, target period, and overall progress metrics of this culture cycle.',
                child: CultureProgressCard(
                  createdAt: widget.createdAt,
                  targetCulturePeriodDays: widget.targetCulturePeriodDays,
                ),
              ),
              WeatherOverviewCard(
                pondId: widget.pondId,
                pondName: widget.pondName,
                latitude: lat,
                longitude: lon,
                canEdit: canEdit,
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: CustomShowcase(
                  showcaseKey: _calendarKey,
                  scope: 'pond_monitoring',
                  title: 'Monitoring Calendar',
                  description: 'Select a day to view historical records, trends, or log daily parameters.',
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceContainer
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: isDark
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: MonitoringCalendar(
                      pondId: widget.pondId,
                      focusedDay: widget.focusedDay,
                      selectedDay: widget.selectedDay,
                      firstDay: widget.createdAt,
                      lastDay: widget.createdAt.add(Duration(days: widget.targetCulturePeriodDays)),
                      onDaySelected: widget.onDaySelected,
                      onPageChanged: widget.onPageChanged,
                    ),
                  ),
                ),
              ),
              if (widget.userRole == 'owner' || widget.userRole == 'editor')
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: CustomShowcase(
                      showcaseKey: _recordButtonKey,
                      scope: 'pond_monitoring',
                      title: 'Record Parameters',
                      description: 'Tap here to enter daily water quality data such as temperature, pH, and dissolved oxygen.',
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (widget.selectedDay == null) {
                            SnackbarHelper.showInfo(context, 'Please select a day first on the calendar.');
                            return;
                          }
                          widget.onRecordParameters();
                        },
                        icon: const Icon(Icons.water_drop_rounded),
                        label: const Text('Record Parameters'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
