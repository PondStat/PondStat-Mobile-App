import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_background.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/monitoring_header.dart';
import 'package:pondstat/features/profile/presentation/profile_bottom_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_history_sheet.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';

import 'operations_page.dart';
import 'overview_tab.dart';
import 'water_quality_page.dart';
import 'growth_page.dart';
import 'trends_page.dart';

class PondMonitoringScaffold extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String userRole;
  final String species;
  final DateTime createdAt;
  final int targetCulturePeriodDays;

  const PondMonitoringScaffold({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
    required this.species,
    required this.createdAt,
    required this.targetCulturePeriodDays,
  });

  @override
  ConsumerState<PondMonitoringScaffold> createState() => _PondMonitoringScaffoldState();
}

class _PondMonitoringScaffoldState extends ConsumerState<PondMonitoringScaffold> {
  int _currentIndex = 2;
  final Set<int> _visitedTabs = {2};
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool get canEdit => widget.userRole == 'owner' || widget.userRole == 'editor';

  final GlobalKey _profileKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ShowcaseView.register(
      scope: 'pond_monitoring',
      onFinish: () {
        if (!mounted) return;
        final tourNotifier = ref.read(onboardingTourProvider);
        if (widget.userRole == 'owner' &&
            !tourNotifier.hasSeenCollaborators) {
          Future.delayed(const Duration(milliseconds: 400), () {
            if (!mounted) return;
            ShowcaseView.getNamed('pond_monitoring').startShowCase([_profileKey]);
            ref.read(onboardingTourProvider.notifier).markCollaboratorsAsSeen();
          });
        }
      },
    );
    final now = DateTime.now();

    final firstDay = widget.createdAt;
    final lastDay = widget.createdAt.add(
      Duration(days: widget.targetCulturePeriodDays),
    );

    DateTime initialFocus = now;
    if (initialFocus.isBefore(firstDay)) {
      initialFocus = firstDay;
    } else if (initialFocus.isAfter(lastDay)) {
      initialFocus = lastDay;
    }

    _focusedDay = initialFocus;
    _selectedDay = DateTime.utc(
      initialFocus.year,
      initialFocus.month,
      initialFocus.day,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tourNotifier = ref.read(onboardingTourProvider);
      if (widget.userRole == 'owner' &&
          tourNotifier.hasSeenOverview &&
          !tourNotifier.hasSeenCollaborators) {
        ShowcaseView.getNamed('pond_monitoring').startShowCase([_profileKey]);
      }
    });
  }



  void _showProfileSheet() {
    final tourState = ref.read(onboardingTourProvider);
    final shouldStartTour = widget.userRole == 'owner' && !tourState.hasSeenCollaborators;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileBottomSheet(
        currentPondId: widget.pondId,
        currentPondName: widget.pondName,
        currentUserRole: widget.userRole,
        startCollaboratorTour: shouldStartTour,
      ),
    );
  }

  void _showEditHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        snap: true,
        builder: (context, scrollController) => EditHistorySheet(
          pondId: widget.pondId,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    ShowcaseView.getNamed('pond_monitoring').unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Tab order: Operations(0), Trends(1), Overview(2), Growth(3), Parameter(4)
    Widget buildTab(int index) {
      switch (index) {
        case 0:
          return OperationsPage(
            pondId: widget.pondId,
            pondName: widget.pondName,
            userRole: widget.userRole,
            canEdit: widget.userRole == 'owner',
          );
        case 1:
          return TrendsPage(
            pondId: widget.pondId,
            species: widget.species,
            userRole: widget.userRole,
          );
        case 2:
          return OverviewTab(
            pondId: widget.pondId,
            pondName: widget.pondName,
            userRole: widget.userRole,
            species: widget.species,
            createdAt: widget.createdAt,
            targetCulturePeriodDays: widget.targetCulturePeriodDays,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = DateTime.utc(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            onRecordParameters: () {
              setState(() {
                _currentIndex = 4;
                _visitedTabs.add(4);
              });
            },
          );
        case 3:
          if (_selectedDay != null) {
            return GrowthPage(
              pondId: widget.pondId,
              pondName: widget.pondName,
              species: widget.species,
              canEdit: canEdit,
              selectedDay: _selectedDay!,
            );
          }
          return const SizedBox.shrink();
        case 4:
          if (_selectedDay != null) {
            return WaterQualityPage(
              pondId: widget.pondId,
              pondName: widget.pondName,
              species: widget.species,
              canEdit: canEdit,
              selectedDay: _selectedDay!,
            );
          }
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: EmptyStateCard(
                  image: const Icon(Icons.calendar_month_rounded),
                  title: "No Day Selected",
                  description:
                      "Select a day on the calendar in the Overview tab to view water quality parameters.",
                  action: ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _currentIndex = 2);
                    },
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text('Go to Calendar'),
                  ),
                ),
              ),
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const PondBackground(),
          SafeArea(
            child: Column(
              children: [
                MonitoringHeader(
                  pondId: widget.pondId,
                  pondName: widget.pondName,
                  species: widget.species,
                  onBackTap: () => context.pop(),
                  onHistoryTap: _showEditHistory,
                  onProfileTap: _showProfileSheet,
                  profileKey: _profileKey,
                  onHelpTap: () {
                    ref.read(tourTriggerProvider.notifier).state = null;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref.read(tourTriggerProvider.notifier).state = _currentIndex;
                    });
                  },
                ),
                Expanded(
                  child: FadeIndexedStack(
                    index: _currentIndex,
                    children: List.generate(5, (index) {
                      if (!_visitedTabs.contains(index)) {
                        return const SizedBox.shrink();
                      }
                      return buildTab(index);
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
        ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
                _visitedTabs.add(index);
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: colorScheme.surface,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurfaceVariant.withValues(
              alpha: 0.6,
            ),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_rounded),
                label: "Operations",
                tooltip: "Operations",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics_rounded),
                label: "Trends",
                tooltip: "Trends",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: "Overview",
                tooltip: "Overview",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.trending_up_rounded),
                label: "Growth",
                tooltip: "Growth",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.water_drop_rounded),
                label: "Parameter",
                tooltip: "Parameter",
              ),
            ],
          ),
        ),
    );
  }
}

class FadeIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
      child: IndexedStack(
        index: widget.index,
        children: widget.children,
      ),
    );
  }
}
