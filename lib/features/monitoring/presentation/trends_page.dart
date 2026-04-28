import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/trends_tab.dart';
import 'package:pondstat/features/monitoring/presentation/periodic_parameters_chart.dart';
import 'package:pondstat/core/utils/helpers.dart';

class TrendsPage extends StatelessWidget {
  final String pondId;
  final String species;

  const TrendsPage({super.key, required this.pondId, required this.species});

  void _exportReport(BuildContext context) {
    SnackbarHelper.show(context, "Export functionality coming soon", backgroundColor: Colors.red.shade400);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF0A74DA),
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: const Color(0xFF0A74DA),
            tabs: const [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Biweekly"),
              Tab(text: "Historical"),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: PeriodicParametersChart(pondId: pondId, species: species, type: 'daily'),
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: PeriodicParametersChart(pondId: pondId, species: species, type: 'weekly'),
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: PeriodicParametersChart(pondId: pondId, species: species, type: 'biweekly'),
                  ),
                ),
                TrendsTab(pondId: pondId, species: species),
              ],
            ),
            Positioned(
              top: 8,
              right: 20,
              child: FloatingActionButton.small(
                heroTag: 'export_btn',
                backgroundColor: Colors.red.shade50,
                elevation: 0,
                onPressed: () => _exportReport(context),
                child: Icon(Icons.ios_share_rounded, color: Colors.red.shade400),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
