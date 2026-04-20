import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_helper.dart';

class MonitoringCalendar extends StatelessWidget {
  final String pondId;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final VoidCallback? onReturnToToday;

  const MonitoringCalendar({
    super.key,
    required this.pondId,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    this.onReturnToToday,
  });

  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);
  final Color textDark = const Color(0xFF1E293B);
  final Color textMuted = const Color(0xFF64748B);

  Widget _buildStatusDot(Color color, bool isSelected) {
    return Container(
      width: isSelected ? 8 : 6,
      height: isSelected ? 8 : 6,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: isSelected ? Border.all(color: Colors.white, width: 1.5) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .where('pondId', isEqualTo: pondId)
          .snapshots(includeMetadataChanges: true),
      builder: (context, snapshot) {
        Map<DateTime, Set<String>> eventsMap = {};

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final type = data['type'] as String?;

            if (timestamp != null && type != null) {
              final date = timestamp.toDate();
              final normalizedDate = DateTime.utc(
                date.year,
                date.month,
                date.day,
              );
              eventsMap.putIfAbsent(normalizedDate, () => {}).add(type);
            }
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 4,
                top: 4,
                bottom: 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${_getMonthName(focusedDay.month)} ${focusedDay.year}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (onReturnToToday != null &&
                      !isSameDay(focusedDay, DateTime.now()))
                    TextButton.icon(
                      onPressed: onReturnToToday,
                      icon: const Icon(Icons.today_rounded, size: 16),
                      label: const Text(
                        "Today",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryBlue,
                        backgroundColor: primaryBlue.withValues(alpha: 0.05),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ),

            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.now(),
              focusedDay: focusedDay,
              startingDayOfWeek: StartingDayOfWeek.monday,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              headerVisible: false,

              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  color: textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                weekendStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                dowTextFormatter: (date, locale) =>
                    _getDowName(date.weekday).toUpperCase(),
              ),

              calendarStyle: CalendarStyle(
                cellMargin: const EdgeInsets.all(4),
                outsideDaysVisible: false,
                defaultTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  fontSize: 15,
                ),
                weekendTextStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  fontSize: 15,
                ),
              ),

              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: onDaySelected,

              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, date, events) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [secondaryBlue, primaryBlue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
                todayBuilder: (context, date, events) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
                markerBuilder: (context, date, events) {
                  final normalizedDate = DateTime.utc(
                    date.year,
                    date.month,
                    date.day,
                  );
                  final types = eventsMap[normalizedDate] ?? {};

                  if (types.isEmpty) return const SizedBox();

                  final isSelected = isSameDay(selectedDay, date);

                  List<Widget> activeDots = [];
                  if (types.contains('daily')) {
                    activeDots.add(
                      _buildStatusDot(Colors.green.shade400, isSelected),
                    );
                  }
                  if (types.contains('weekly')) {
                    activeDots.add(
                      _buildStatusDot(Colors.amber.shade400, isSelected),
                    );
                  }
                  if (types.contains('biweekly')) {
                    activeDots.add(_buildStatusDot(primaryBlue, isSelected));
                  }

                  return Positioned(
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: activeDots,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String _getDowName(int weekday) {
    const dows = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return dows[weekday - 1];
  }
}
