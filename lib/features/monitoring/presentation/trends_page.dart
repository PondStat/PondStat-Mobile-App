import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      SnackbarHelper.show(context, "Only the owner can set the date range.", backgroundColor: Colors.orange.shade600);
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

  void _exportReport(BuildContext context) {
    SnackbarHelper.show(context, "Export functionality coming soon", backgroundColor: Colors.red.shade400);
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
            boxShadow: isDark ? [] : [
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
                  color: isOwner ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
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
                          child: PeriodicParametersChart(pondId: widget.pondId, species: widget.species, type: 'daily', startDate: _startDate, endDate: _endDate),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PeriodicParametersChart(pondId: widget.pondId, species: widget.species, type: 'weekly', startDate: _startDate, endDate: _endDate),
                        ),
                      ),
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: PeriodicParametersChart(pondId: widget.pondId, species: widget.species, type: 'biweekly', startDate: _startDate, endDate: _endDate),
                        ),
                      ),
                      TrendsTab(pondId: widget.pondId, species: widget.species, userRole: widget.userRole, startDate: _startDate, endDate: _endDate),
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
          ],
        ),
      ),
    );
  }
}
