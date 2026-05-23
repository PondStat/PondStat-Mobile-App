import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/assign_shift_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/shift_expansion_tile.dart';

class SchedulesTab extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final bool canEdit;

  const SchedulesTab({
    super.key,
    required this.pondId,
    required this.pondName,
    this.canEdit = true,
  });

  @override
  ConsumerState<SchedulesTab> createState() => _SchedulesTabState();
}

class _SchedulesTabState extends ConsumerState<SchedulesTab>
    with AutomaticKeepAliveClientMixin {
  Color get primaryBlue => Theme.of(context).colorScheme.primary;
  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  late Stream<QuerySnapshot> _schedulesStream;

  final GlobalKey _shiftsListKey = GlobalKey();
  final GlobalKey _assignShiftsKey = GlobalKey();

  void _startTour() {
    final keys = [_shiftsListKey];
    if (widget.canEdit) {
      keys.add(_assignShiftsKey);
    }
    ShowcaseView.get().startShowCase(keys);
  }

  void _initStream() {
    _schedulesStream = ref.read(monitoringRepositoryProvider).schedulesCollection
        .where('pondId', isEqualTo: widget.pondId)
        .snapshots();
  }

  Future<void> _refreshData() async {
    setState(() {
      _initStream();
    });
    try {
      await _schedulesStream.first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(onboardingTourProvider).hasSeenOperations;
      if (!hasSeen) {
        _startTour();
        ref.read(onboardingTourProvider.notifier).markOperationsAsSeen();
      }
    });
  }

  @override
  void didUpdateWidget(covariant SchedulesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _initStream();
    }
  }

  @override
  bool get wantKeepAlive => true;

  void _showAssignSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => AssignShiftSheet(
          pondId: widget.pondId,
          pondName: widget.pondName,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    ref.listen<int?>(tourTriggerProvider, (previous, next) {
      if (next == 0) {
        final tabController = DefaultTabController.maybeOf(context);
        if (tabController == null || tabController.index == 0) {
          _startTour();
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: _schedulesStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorStateCard(
              description: "Error loading schedules: ${snapshot.error}",
              onRetry: _refreshData,
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingPlaceholder(message: "Loading schedules...");
          }

          final docs = snapshot.data?.docs ?? [];

          // Parse schedules into a grouped format: day -> shift -> List of user objects
          final Map<String, Map<String, List<Map<String, dynamic>>>>
          groupedSchedules = {
            for (var day in _daysOfWeek) day: {'morning': [], 'afternoon': []},
          };

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final scheduleVal = data['schedule'];
            final schedule = scheduleVal is Map ? scheduleVal : null;
            final userName = data['userName'] ?? 'Unknown User';
            final userId = data['userId'] ?? doc.id;

            if (schedule != null) {
              for (var day in _daysOfWeek) {
                if (schedule.containsKey(day) && schedule[day] is Map) {
                  final dayMap = schedule[day] as Map;
                  if (dayMap['morning'] == true) {
                    groupedSchedules[day]!['morning']!.add({
                      'id': userId,
                      'name': userName,
                    });
                  }
                  if (dayMap['afternoon'] == true) {
                    groupedSchedules[day]!['afternoon']!.add({
                      'id': userId,
                      'name': userName,
                    });
                  }
                }
              }
            }
          }

          // Check if all schedules are empty
          bool isCompletelyEmpty = true;
          for (var day in _daysOfWeek) {
            if (groupedSchedules[day]!['morning']!.isNotEmpty ||
                groupedSchedules[day]!['afternoon']!.isNotEmpty) {
              isCompletelyEmpty = false;
              break;
            }
          }

          bool didShowcaseShiftCard = false;

          return RefreshIndicator(
            onRefresh: _refreshData,
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: isCompletelyEmpty && !widget.canEdit
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: CustomShowcase(
                      showcaseKey: _shiftsListKey,
                      title: 'Shift Schedules',
                      description: 'View the assigned morning and afternoon shifts for each day of the week.',
                      child: EmptyStateCard(
                        image: const Icon(Icons.event_busy_rounded),
                        title: 'No Schedules Assigned',
                        description:
                            'There are currently no shifts scheduled for this pond.',
                        scrollable: true,
                      ),
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(
                      top: 12,
                      left: 20,
                      right: 20,
                      bottom: 100, // padding for FAB
                    ),
                    itemCount: _daysOfWeek.length,
                    itemBuilder: (context, index) {
                      final day = _daysOfWeek[index];
                      final morningUsers = groupedSchedules[day]!['morning']!;
                      final afternoonUsers = groupedSchedules[day]!['afternoon']!;

                      // Only show days that have at least one assignment, unless we are in edit mode
                      // If edit mode, show all days so they can see nothing is assigned.
                      if (morningUsers.isEmpty &&
                          afternoonUsers.isEmpty &&
                          !widget.canEdit) {
                        return const SizedBox.shrink();
                      }

                      Widget dayCard = _buildDayCard(day, morningUsers, afternoonUsers);
                      if (!didShowcaseShiftCard) {
                        didShowcaseShiftCard = true;
                        dayCard = CustomShowcase(
                          showcaseKey: _shiftsListKey,
                          title: 'Shift Schedules',
                          description: 'View the assigned morning and afternoon shifts for each day of the week.',
                          child: dayCard,
                        );
                      }

                      return StaggeredListItem(
                        index: index,
                        child: dayCard,
                      );
                    },
                  ),
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? CustomShowcase(
              showcaseKey: _assignShiftsKey,
              title: 'Assign Shifts',
              description: 'Assign or modify shifts for team members and coordinators.',
              child: Semantics(
                label: "Assign schedules or shifts to pond collaborators",
                button: true,
                child: FloatingActionButton.extended(
                  heroTag: 'schedules_fab',
                  onPressed: _showAssignSheet,
                  backgroundColor: primaryBlue,
                  icon: const Icon(Icons.group_add_rounded, color: Colors.white),
                  label: const Text(
                    "Assign Shifts",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDayCard(
    String day,
    List<Map<String, dynamic>> morningUsers,
    List<Map<String, dynamic>> afternoonUsers,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: onSurface,
              ),
            ),
          ),
          ShiftExpansionTile(
            shiftName: "Morning",
            icon: Icons.wb_sunny_rounded,
            iconColor: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
            bgColor: isDark ? Colors.amber.withValues(alpha: 0.15) : Colors.amber.shade50,
            assignedUsers: morningUsers,
          ),
          Divider(
            height: 1,
            color: colorScheme.outlineVariant,
            indent: 16,
            endIndent: 16,
          ),
          ShiftExpansionTile(
            shiftName: "Afternoon",
            icon: Icons.wb_twilight_rounded,
            iconColor: isDark ? Colors.indigo.shade300 : Colors.indigo.shade600,
            bgColor: isDark ? Colors.indigo.withValues(alpha: 0.2) : Colors.indigo.shade50,
            assignedUsers: afternoonUsers,
          ),
        ],
      ),
    );
  }
}
