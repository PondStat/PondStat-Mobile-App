import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/schedules_tab.dart';
import 'package:pondstat/features/monitoring/presentation/finances_tab.dart';

class OperationsPage extends StatelessWidget {
  final String pondId;
  final String pondName;
  final String userRole;
  final bool canEdit;

  const OperationsPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF0A74DA),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.grey.shade600,
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              tabs: const [
                Tab(text: "Schedules"),
                Tab(text: "Finances"),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            SchedulesTab(pondId: pondId, pondName: pondName, canEdit: canEdit),
            FinancesTab(pondId: pondId, canEdit: canEdit),
          ],
        ),
      ),
    );
  }
}
