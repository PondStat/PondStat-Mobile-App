import 'package:flutter/material.dart';
import 'overview_tab.dart';
import 'water_quality_page.dart';
import 'growth_page.dart';
import 'expenses_page.dart';
import 'trends_page.dart';

class PondMonitoringScaffold extends StatefulWidget {
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
  State<PondMonitoringScaffold> createState() => _PondMonitoringScaffoldState();
}

class _PondMonitoringScaffoldState extends State<PondMonitoringScaffold> {
  int _currentIndex = 0;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  bool get canEdit => widget.userRole == 'owner' || widget.userRole == 'editor';
  final Color primaryBlue = const Color(0xFF0A74DA);
  final Color secondaryBlue = const Color(0xFF4FA0F0);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = now;
    _selectedDay = DateTime.utc(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      OverviewTab(
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
            _selectedDay = DateTime.utc(selectedDay.year, selectedDay.month, selectedDay.day);
            _focusedDay = focusedDay;
          });
        },
        primaryBlue: primaryBlue,
        secondaryBlue: secondaryBlue,
      ),
      if (_selectedDay != null)
        WaterQualityPage(
          pondId: widget.pondId,
          pondName: widget.pondName,
          species: widget.species,
          canEdit: canEdit,
          selectedDay: _selectedDay!,
        )
      else
        const Scaffold(body: Center(child: Text("Please select a day from the Overview tab to view Water Quality"))),
      GrowthPage(
        pondId: widget.pondId,
        canEdit: canEdit,
      ),
      ExpensesPage(
        pondId: widget.pondId,
        canEdit: canEdit,
      ),
      TrendsPage(
        pondId: widget.pondId,
        species: widget.species,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
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
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: "Overview",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop_rounded),
              label: "Water",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up_rounded),
              label: "Growth",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: "Expenses",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_rounded),
              label: "Trends",
            ),
          ],
        ),
      ),
    );
  }
}
