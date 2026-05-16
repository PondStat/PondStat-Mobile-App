import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class MonitoringCalendar extends StatelessWidget {
  final String pondId;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime)? onPageChanged;
  final VoidCallback? onReturnToToday;
  final DateTime firstDay;
  final DateTime lastDay;

  const MonitoringCalendar({
    super.key,
    required this.pondId,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    this.onPageChanged,
    required this.firstDay,
    required this.lastDay,
    this.onReturnToToday,
  });

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

  Widget _buildLegendItem(Color color, String label, Color textMuted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final Color textDark = colorScheme.onSurface;
    final Color textMuted = colorScheme.onSurfaceVariant;

    // Constrain the query to the visible month to prevent a Firestore read bomb
    final startOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final endOfMonth = DateTime(
      focusedDay.year,
      focusedDay.month + 1,
      0,
      23,
      59,
      59,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreHelper.measurementsCollection
          .where('pondId', isEqualTo: pondId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where(
            'timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth),
          )
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
                        foregroundColor: primaryColor,
                        backgroundColor: primaryColor.withValues(alpha: 0.05),
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
              firstDay: firstDay,
              lastDay: lastDay,
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
                  color: textMuted.withValues(alpha: 0.5),
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
                  color: textDark.withValues(alpha: 0.5),
                  fontSize: 15,
                ),
              ),

              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: onDaySelected,
              onPageChanged: onPageChanged,

              calendarBuilders: CalendarBuilders(
                selectedBuilder: (context, date, events) {
                  return Container(
                    margin: const EdgeInsets.all(6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
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
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        color: primaryColor,
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
                    activeDots.add(_buildStatusDot(primaryColor, isSelected));
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

            // Legend
            Padding(
              padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.green.shade400, "Daily", textMuted),
                  const SizedBox(width: 16),
                  _buildLegendItem(Colors.amber.shade400, "Weekly", textMuted),
                  const SizedBox(width: 16),
                  _buildLegendItem(primaryColor, "Biweekly/Growth", textMuted),
                ],
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
