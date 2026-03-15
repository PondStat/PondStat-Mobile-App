import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase/firestore_helper.dart';

class MonitoringCalendar extends StatelessWidget {
  final String pondId;
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final Function(DateTime, DateTime) onDaySelected;

  const MonitoringCalendar({
    super.key,
    required this.pondId,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
  });

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
              final normalizedDate = DateTime.utc(date.year, date.month, date.day);
              eventsMap.putIfAbsent(normalizedDate, () => {}).add(type);
            }
          }
        }

        return TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: focusedDay,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},

          headerStyle: const HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black54),
            rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black54),
          ),

          calendarStyle: CalendarStyle(
            cellMargin: const EdgeInsets.all(6),
            outsideDaysVisible: false,
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF0077C2),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF0077C2), width: 1.5),
            ),
            todayTextStyle: const TextStyle(
              color: Color(0xFF0077C2),
              fontWeight: FontWeight.bold,
            ),
            defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
            weekendTextStyle: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),

          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,

          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final normalizedDate = DateTime.utc(date.year, date.month, date.day);
              final types = eventsMap[normalizedDate] ?? {};

              if (types.isEmpty) return const SizedBox();

              List<Widget> activeDots = [];
              if (types.contains('daily')) {
                activeDots.add(_buildStatusDot(Colors.green));
              }
              if (types.contains('weekly')) {
                activeDots.add(_buildStatusDot(Colors.amber));
              }
              if (types.contains('biweekly')) {
                activeDots.add(_buildStatusDot(Colors.blue));
              }

              return Positioned(
                bottom: 6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: activeDots,
                ),
              );
            },
          ),
        );
      },
    );
  }
}