import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/culture_progress_card.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_calendar.dart';

class OverviewTab extends StatelessWidget {
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
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              top: 16.0,
              bottom: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pondName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Target Species: $species",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          CultureProgressCard(
            createdAt: createdAt,
            targetCulturePeriodDays: targetCulturePeriodDays,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
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
                pondId: pondId,
                focusedDay: focusedDay,
                selectedDay: selectedDay,
                firstDay: createdAt,
                lastDay: createdAt.add(Duration(days: targetCulturePeriodDays)),
                onDaySelected: onDaySelected,
                onPageChanged: onPageChanged,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
