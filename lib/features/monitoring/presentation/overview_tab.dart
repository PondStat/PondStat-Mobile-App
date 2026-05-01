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
  final Color primaryBlue;
  final Color secondaryBlue;

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
    required this.primaryBlue,
    required this.secondaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CultureProgressCard(
            createdAt: createdAt,
            targetCulturePeriodDays: targetCulturePeriodDays,
            primaryBlue: primaryBlue,
            secondaryBlue: secondaryBlue,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
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
