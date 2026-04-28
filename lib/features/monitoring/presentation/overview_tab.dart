import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/dashboard/presentation/widgets/pond_background.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/monitoring_header.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_info_card.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_calendar.dart';
import 'package:pondstat/features/profile/presentation/profile_bottom_sheet.dart';
import 'package:pondstat/features/monitoring/presentation/edit_history_sheet.dart';

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
    required this.primaryBlue,
    required this.secondaryBlue,
  });

  void _showProfileSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileBottomSheet(
        currentPondId: pondId,
        currentPondName: pondName,
        currentUserRole: userRole,
      ),
    );
  }

  void _showEditHistory(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => EditHistorySheet(
          pondId: pondId,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const PondBackground(),
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                MonitoringHeader(
                  pondId: pondId,
                  onBackTap: () => Navigator.pop(context),
                  onHistoryTap: () => _showEditHistory(context),
                  onProfileTap: () => _showProfileSheet(context),
                  primaryBlue: primaryBlue,
                  secondaryBlue: secondaryBlue,
                ),
                PondInfoCard(
                  pondName: pondName,
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
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
