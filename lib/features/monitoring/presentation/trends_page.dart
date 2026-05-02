import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';
import 'package:pondstat/features/monitoring/presentation/trends_tab.dart';
import 'package:pondstat/features/monitoring/presentation/periodic_parameters_chart.dart';
import 'package:pondstat/core/utils/helpers.dart';

class TrendsPage extends StatefulWidget {
  final String pondId;
  final String species;
  final String userRole;

  const TrendsPage({
    super.key,
    required this.pondId,
    required this.species,
    required this.userRole,
  });

  @override
  State<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends State<TrendsPage> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 7));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    if (widget.userRole != 'owner') {
      SnackbarHelper.show(
        context,
        "Only the owner can set the date range.",
        backgroundColor: Colors.orange.shade600,
      );
      return;
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0A74DA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null &&
        (picked.start != _startDate || picked.end != _endDate)) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _exportReport(BuildContext context) async {
    try {
      SnackbarHelper.show(context, "Generating report...");

      final querySnapshot = await FirestoreHelper.getMeasurementsByDateRange(
        widget.pondId,
        _startDate,
        _endDate,
      ).get();

      if (querySnapshot.docs.isEmpty) {
        if (!context.mounted) return;
        SnackbarHelper.show(
          context,
          "No data to export for this date range.",
          backgroundColor: Colors.orange.shade600,
        );
        return;
      }

      List<List<dynamic>> rows = [
        ["Date", "Time", "Type", "Parameter", "Value", "Unit"],
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final ts =
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(ts);
        final timeStr = DateFormat('HH:mm').format(ts);
        final type = data['type']?.toString() ?? 'N/A';
        final parameter = data['parameter']?.toString() ?? 'N/A';
        final value = data['value']?.toString() ?? 'N/A';
        final unit = data['unit']?.toString() ?? '';

        rows.add([dateStr, timeStr, type, parameter, value, unit]);
      }

      String csvData = csv.encode(rows);

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/PondStat_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'PondStat Water Quality Report',
        ),
      );

      if (result.status == ShareResultStatus.success) {
        if (!context.mounted) return;
        SnackbarHelper.show(
          context,
          "Report exported successfully!",
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackbarHelper.show(
        context,
        "Failed to export report: $e",
        backgroundColor: Colors.red.shade600,
      );
    }
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final bool isOwner = widget.userRole == 'owner';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: InkWell(
        onTap: () => _selectDateRange(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOwner
                  ? const Color(0xFF0A74DA).withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.date_range_rounded,
                color: isOwner ? const Color(0xFF0A74DA) : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isOwner
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
              if (!isOwner) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock_rounded, size: 16, color: Colors.grey),
              ],
            ],
          ),
        ),
      ),
    );
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
            isScrollable: false,
            labelColor: const Color(0xFF0A74DA),
            unselectedLabelColor: Colors.grey.shade400,
            indicatorColor: const Color(0xFF0A74DA),
            tabs: const [
              Tab(text: "Daily"),
              Tab(text: "Weekly"),
              Tab(text: "Biweekly"),
              Tab(text: "Final"),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildDateRangeSelector(context),
            Expanded(
              child: Stack(
                children: [
                  TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PeriodicParametersChart(
                            pondId: widget.pondId,
                            species: widget.species,
                            type: 'daily',
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PeriodicParametersChart(
                            pondId: widget.pondId,
                            species: widget.species,
                            type: 'weekly',
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PeriodicParametersChart(
                            pondId: widget.pondId,
                            species: widget.species,
                            type: 'biweekly',
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                      ),
                      TrendsTab(
                        pondId: widget.pondId,
                        species: widget.species,
                        userRole: widget.userRole,
                        startDate: _startDate,
                        endDate: _endDate,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'export_btn',
          onPressed: () => _exportReport(context),
          backgroundColor: const Color(0xFF0A74DA),
          icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
          label: const Text(
            "Export CSV",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
