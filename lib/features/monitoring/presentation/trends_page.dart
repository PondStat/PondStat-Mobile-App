import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:pondstat/features/monitoring/presentation/periodic_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/trends_tab.dart';
import 'package:pondstat/features/monitoring/presentation/correlation_tab.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/onboarding_tour_provider.dart';
import 'package:pondstat/features/monitoring/presentation/utils/trends_exporter.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
import 'package:pondstat/features/monitoring/data/finances_repository.dart';

class TrendsPage extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String species;
  final String userRole;

  const TrendsPage({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.userRole,
  });

  @override
  ConsumerState<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends ConsumerState<TrendsPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isExporting = false;

  final GlobalKey _dateRangeKey = GlobalKey();
  final GlobalKey _trendsTabsKey = GlobalKey();
  final GlobalKey _weatherOverlayKey = GlobalKey();
  final GlobalKey _exportReportKey = GlobalKey();

  void _startTour() {
    ShowcaseView.getNamed('pond_monitoring').startShowCase([
      _trendsTabsKey,
      _dateRangeKey,
      _weatherOverlayKey,
      _exportReportKey,
    ]);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 7));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasSeen = ref.read(onboardingTourProvider).hasSeenTrends;
      if (!hasSeen) {
        _startTour();
        ref.read(onboardingTourProvider.notifier).markTrendsAsSeen();
      }
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    if (widget.userRole != 'owner' && widget.userRole != 'editor') {
      SnackbarHelper.showInfo(context, "Only owners and editors can set the date range.");
      return;
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0A74DA),
              brightness: brightness,
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

  Future<void> _exportReportFormat(BuildContext context, String format) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    final monitoringRepo = ref.read(monitoringRepositoryProvider);
    final growthRepo = ref.read(growthRepositoryProvider);
    final financesRepo = ref.read(financesRepositoryProvider);

    try {
      await TrendsExporter.exportReport(
        context: context,
        format: format,
        monitoringRepo: monitoringRepo,
        growthRepo: growthRepo,
        financesRepo: financesRepo,
        pondName: widget.pondName,
        boundaryKey: _boundaryKey,
        pondId: widget.pondId,
        species: widget.species,
        startDate: _startDate,
        endDate: _endDate,
      );
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, "Failed to export report: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;

        Widget optionCard({
          required IconData icon,
          required Color iconColor,
          required Color bgIconColor,
          required String title,
          required String description,
          required VoidCallback onTap,
        }) {
          return InkWell(
            onTap: () {
              Navigator.pop(context);
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : colorScheme.outlineVariant,
                ),
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: bgIconColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white60 : Colors.black45,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            top: 12,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Export Report",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Choose your preferred format",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : colorScheme.outlineVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              optionCard(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: const Color(0xFFE44A4A),
                bgIconColor: const Color(0xFFE44A4A).withValues(alpha: 0.1),
                title: "PDF Document",
                description: "Structured PDF with visual charts and log history",
                onTap: () => _exportReportFormat(context, 'pdf'),
              ),
              const SizedBox(height: 12),
              optionCard(
                icon: Icons.image_rounded,
                iconColor: const Color(0xFF0A74DA),
                bgIconColor: const Color(0xFF0A74DA).withValues(alpha: 0.1),
                title: "High-Res Image",
                description: "Visual capture of current chart layout (PNG)",
                onTap: () => _exportReportFormat(context, 'image'),
              ),
              const SizedBox(height: 12),
              optionCard(
                icon: Icons.table_rows_rounded,
                iconColor: const Color(0xFF107C41),
                bgIconColor: const Color(0xFF107C41).withValues(alpha: 0.1),
                title: "CSV Spreadsheet",
                description: "Raw parameter logs in Excel-compatible grid",
                onTap: () => _exportReportFormat(context, 'csv'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    final bool hasAccess = widget.userRole == 'owner' || widget.userRole == 'editor';
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
              color: hasAccess
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
                color: hasAccess ? const Color(0xFF0A74DA) : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: hasAccess
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
              if (!hasAccess) ...[
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
    ref.listen<int?>(tourTriggerProvider, (previous, next) {
      if (next == 1) { // Trends is index 1
        _startTour();
      }
    });

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RepaintBoundary(
          key: _boundaryKey,
          child: Column(
            children: [
              CustomShowcase(
                showcaseKey: _trendsTabsKey,
                scope: 'pond_monitoring',
                title: 'Periodic Filters',
                description: 'Switch between Daily, Weekly, Biweekly, Final, and Correlation analysis views of your pond parameters.',
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: const Color(0xFF0A74DA),
                          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                          indicatorColor: const Color(0xFF0A74DA),
                          labelPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                          tabs: const [
                            Tab(text: "Daily"),
                            Tab(text: "Weekly"),
                            Tab(text: "Biweekly"),
                            Tab(text: "Final"),
                            Tab(text: "Correlation"),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CustomShowcase(
                showcaseKey: _dateRangeKey,
                scope: 'pond_monitoring',
                title: 'Date Range Selector',
                description: 'Filter parameters over custom historical durations (Only editable by the Pond Owner).',
                child: _buildDateRangeSelector(context),
              ),
              Expanded(
                child: Stack(
                  children: [
                    TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 100),
                            child: PeriodicParametersChart(
                              pondId: widget.pondId,
                              species: widget.species,
                              type: 'daily',
                              startDate: _startDate,
                              endDate: _endDate,
                              weatherOverlayKey: _weatherOverlayKey,
                            ),
                          ),
                        ),
                        SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 100),
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
                            padding: const EdgeInsets.only(top: 12, bottom: 100),
                            child: PeriodicParametersChart(
                              pondId: widget.pondId,
                              species: widget.species,
                              type: 'biweekly',
                              startDate: _startDate,
                              endDate: _endDate,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: TrendsTab(
                            pondId: widget.pondId,
                            species: widget.species,
                            userRole: widget.userRole,
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: CorrelationTab(
                            pondId: widget.pondId,
                            species: widget.species,
                            startDate: _startDate,
                            endDate: _endDate,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: CustomShowcase(
          showcaseKey: _exportReportKey,
          scope: 'pond_monitoring',
          title: 'Export Report',
          description: 'Generate high-resolution PNG charts, raw CSV data, or styled PDF reports to share with your team.',
          child: FloatingActionButton.extended(
            heroTag: 'export_btn',
            onPressed: _isExporting ? null : () => _showExportOptions(context),
            backgroundColor: _isExporting
                ? Colors.grey.shade400
                : const Color(0xFF0A74DA),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.ios_share_rounded, color: Colors.white),
            label: Text(
              _isExporting ? "Exporting..." : "Export Report",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
