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
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
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
              final normalizedDate =
                  DateTime.utc(date.year, date.month, date.day);

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
            titleCentered: false,
            formatButtonVisible: false,
            titleTextStyle:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          calendarStyle: const CalendarStyle(
            cellMargin: EdgeInsets.all(8),
            selectedDecoration:
                BoxDecoration(color: Color(0xFF0077C2), shape: BoxShape.circle),
            todayDecoration:
                BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
          ),
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          onDaySelected: onDaySelected,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final normalizedDate =
                  DateTime.utc(date.year, date.month, date.day);
              final types = eventsMap[normalizedDate] ?? {};

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
                bottom: 1,
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