import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
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
    ShowcaseView.getNamed('pond_monitoring').startShowCase(keys);
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(
                top: 12,
                left: 20,
                right: 20,
                bottom: 120, // padding for FAB
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Text(
                    "👥 SHIFT ASSIGNMENTS",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                if (isCompletelyEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.event_busy_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Shifts Assigned',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'There are currently no shifts scheduled for this pond.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(_daysOfWeek.length, (index) {
                    final day = _daysOfWeek[index];
                    final morningUsers = groupedSchedules[day]!['morning']!;
                    final afternoonUsers = groupedSchedules[day]!['afternoon']!;

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
                        scope: 'pond_monitoring',
                        title: 'Shift Schedules',
                        description: 'View the assigned morning and afternoon shifts for each day of the week.',
                        child: dayCard,
                      );
                    }

                    return StaggeredListItem(
                      index: index,
                      child: dayCard,
                    );
                  }),
                _buildSmartTasksList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: widget.canEdit
          ? CustomShowcase(
              showcaseKey: _assignShiftsKey,
              scope: 'pond_monitoring',
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

  Widget _buildSmartTasksList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> smartDays = [
      {
        'day': 'Monday',
        'type': 'Daily & Weekly biological parameters',
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF009688)],
        'icon': Icons.calendar_today_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency', 'Phytoplankton', 'Test yellow 10-1 (CFU/ml)', 'Test green 10-1 (CFU/ml)'],
      },
      {
        'day': 'Tuesday',
        'type': 'Daily physical/chemical parameters',
        'gradient': [const Color(0xFF03A9F4), const Color(0xFF00BCD4)],
        'icon': Icons.wb_sunny_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency'],
      },
      {
        'day': 'Wednesday',
        'type': 'Daily & Biweekly chemical parameters',
        'gradient': [const Color(0xFF9C27B0), const Color(0xFF673AB7)],
        'icon': Icons.science_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency', 'Dissolved Oxygen', 'Ammonia', 'Nitrite', 'Nitrate', 'Total Alkalinity'],
      },
      {
        'day': 'Thursday',
        'type': 'Daily physical/chemical parameters',
        'gradient': [const Color(0xFF03A9F4), const Color(0xFF00BCD4)],
        'icon': Icons.wb_sunny_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency'],
      },
      {
        'day': 'Friday',
        'type': 'Daily physical/chemical parameters',
        'gradient': [const Color(0xFF03A9F4), const Color(0xFF00BCD4)],
        'icon': Icons.wb_sunny_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency'],
      },
      {
        'day': 'Saturday',
        'type': 'Daily physical/chemical parameters',
        'gradient': [const Color(0xFF03A9F4), const Color(0xFF00BCD4)],
        'icon': Icons.wb_sunny_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency'],
      },
      {
        'day': 'Sunday',
        'type': 'Daily physical/chemical parameters',
        'gradient': [const Color(0xFF03A9F4), const Color(0xFF00BCD4)],
        'icon': Icons.wb_sunny_rounded,
        'params': ['pH Level', 'Temperature', 'Salinity', 'Transparency'],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "📋 SMART MONITORING SCHEDULE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            "Automatically generated based on parameter measurement frequency",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...smartDays.map((sd) {
          final gradientColors = sd['gradient'] as List<Color>;
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: gradientColors.first,
                      width: 6,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: gradientColors.first.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            sd['icon'] as IconData,
                            color: gradientColors.first,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sd['day'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sd['type'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (sd['params'] as List<String>).map((paramName) {
                        final paramColor = _getParameterColor(paramName);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: paramColor.withValues(alpha: isDark ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: paramColor.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getParameterIcon(paramName),
                                size: 12,
                                color: paramColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                paramName,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: paramColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getParameterColor(String label) {
    switch (label) {
      case 'pH Level': return const Color(0xFFE91E63);
      case 'Temperature': return const Color(0xFFFF5722);
      case 'Salinity': return const Color(0xFF03A9F4);
      case 'Transparency': return const Color(0xFFFFC107);
      case 'Phytoplankton': return const Color(0xFF4CAF50);
      case 'Test yellow 10-1 (CFU/ml)': return const Color(0xFFFF9800);
      case 'Test green 10-1 (CFU/ml)': return const Color(0xFF8BC34A);
      case 'Dissolved Oxygen': return const Color(0xFF00BCD4);
      case 'Ammonia': return const Color(0xFFF44336);
      case 'Nitrite': return const Color(0xFF673AB7);
      case 'Nitrate': return const Color(0xFF9C27B0);
      case 'Total Alkalinity': return const Color(0xFF009688);
      default: return const Color(0xFF607D8B);
    }
  }

  IconData _getParameterIcon(String label) {
    switch (label) {
      case 'pH Level': return Icons.water_drop_rounded;
      case 'Temperature': return Icons.thermostat_rounded;
      case 'Salinity': return Icons.grain_rounded;
      case 'Transparency': return Icons.visibility_rounded;
      case 'Phytoplankton': return Icons.biotech_rounded;
      case 'Test yellow 10-1 (CFU/ml)': return Icons.science_rounded;
      case 'Test green 10-1 (CFU/ml)': return Icons.science_rounded;
      case 'Dissolved Oxygen': return Icons.air_rounded;
      case 'Ammonia': return Icons.science_rounded;
      case 'Nitrite': return Icons.science_outlined;
      case 'Nitrate': return Icons.biotech_rounded;
      case 'Total Alkalinity': return Icons.waves_rounded;
      default: return Icons.bar_chart_rounded;
    }
  }
}
