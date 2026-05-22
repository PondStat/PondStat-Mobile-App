import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pondstat/features/monitoring/presentation/periodic_parameters_chart.dart';
import 'package:pondstat/features/monitoring/presentation/trends_tab.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';

class TrendsPage extends ConsumerStatefulWidget {
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
  ConsumerState<TrendsPage> createState() => _TrendsPageState();
}

class _TrendsPageState extends ConsumerState<TrendsPage> {
  final GlobalKey _boundaryKey = GlobalKey();
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = now.subtract(const Duration(days: 7));
  }

  Future<void> _selectDateRange(BuildContext context) async {
    if (widget.userRole != 'owner') {
      SnackbarHelper.showInfo(context, "Only the owner can set the date range.");
      return;
    }

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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

  Future<Uint8List?> _capturePng() async {
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Capture error: $e");
      return null;
    }
  }

  Future<void> _exportReportFormat(BuildContext context, String format) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      SnackbarHelper.showInfo(context, "Generating ${format.toUpperCase()} report...");
      final directory = await getTemporaryDirectory();
      final dateSuffix = DateFormat('yyyyMMdd').format(DateTime.now());

      if (format == 'csv') {
        final querySnapshot = await ref.read(monitoringRepositoryProvider).getMeasurementsByDateRange(
          widget.pondId,
          _startDate,
          _endDate,
        ).get();

        if (querySnapshot.docs.isEmpty) {
          if (!context.mounted) return;
          SnackbarHelper.showInfo(context, "No data to export for this date range.");
          return;
        }

        List<List<dynamic>> rows = [
          ["ISO Timestamp", "Date", "Time", "Type", "Parameter", "Value", "Unit"],
        ];

        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final isoStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(ts);
          final dateStr = DateFormat('yyyy-MM-dd').format(ts);
          final timeStr = DateFormat('HH:mm').format(ts);
          final type = data['type']?.toString() ?? 'N/A';
          final parameter = data['parameter']?.toString() ?? 'N/A';
          final value = data['value']?.toString() ?? 'N/A';
          final unit = data['unit']?.toString() ?? '';

          rows.add([isoStr, dateStr, timeStr, type, parameter, value, unit]);
        }

        String csvData = csv.encode(rows);
        final path = '${directory.path}/PondStat_Report_$dateSuffix.csv';
        final file = File(path);
        await file.writeAsString(csvData);

        final result = await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'PondStat Parameter Report'),
        );

        if (result.status == ShareResultStatus.success) {
          if (!context.mounted) return;
          SnackbarHelper.showSuccess(context, "CSV exported successfully!");
        }
      } else if (format == 'image') {
        final capturedBytes = await _capturePng();
        if (capturedBytes == null) {
          if (!context.mounted) return;
          SnackbarHelper.showError(context, "Failed to capture chart image.");
          return;
        }

        final path = '${directory.path}/PondStat_Chart_$dateSuffix.png';
        final file = File(path);
        await file.writeAsBytes(capturedBytes);

        final result = await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'PondStat Visual Trends Chart'),
        );

        if (result.status == ShareResultStatus.success) {
          if (!context.mounted) return;
          SnackbarHelper.showSuccess(context, "Chart image exported successfully!");
        }
      } else if (format == 'pdf') {
        final capturedBytes = await _capturePng();
        if (capturedBytes == null) {
          if (!context.mounted) return;
          SnackbarHelper.showError(context, "Failed to capture chart image for PDF.");
          return;
        }

        final querySnapshot = await ref.read(monitoringRepositoryProvider).getMeasurementsByDateRange(
          widget.pondId,
          _startDate,
          _endDate,
        ).get();

        final pdf = pw.Document();
        final image = pw.MemoryImage(capturedBytes);

        List<List<String>> tableData = [];
        for (var doc in querySnapshot.docs) {
          final data = doc.data();
          final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
          final dateStr = DateFormat('yyyy-MM-dd').format(ts);
          final timeStr = DateFormat('HH:mm').format(ts);
          final type = data['type']?.toString() ?? 'N/A';
          final parameter = data['parameter']?.toString() ?? 'N/A';
          final value = data['value']?.toString() ?? 'N/A';
          final unit = data['unit']?.toString() ?? '';

          tableData.add([dateStr, timeStr, type, parameter, value, unit]);
        }

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32),
            header: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 12.0),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                padding: const pw.EdgeInsets.only(bottom: 4.0),
                child: pw.Text(
                  'PondStat Automated Report',
                  style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              );
            },
            footer: (pw.Context context) {
              return pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 12.0),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                padding: const pw.EdgeInsets.only(top: 4.0),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated dynamically by PondStat',
                      style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8),
                    ),
                    pw.Text(
                      'Page ${context.pageNumber} of ${context.pagesCount}',
                      style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
            build: (pw.Context context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'PondStat Report',
                        style: pw.TextStyle(
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0A74DA),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Comprehensive Pond Analysis & Metrics',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('Pond ID: ${widget.pondId}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('Species: ${widget.species}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0x0F0A74DA),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Date Range: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: const PdfColor.fromInt(0xFF0A74DA)),
                    ),
                    pw.Text(
                      '${DateFormat('MMMM d, yyyy').format(_startDate)} - ${DateFormat('MMMM d, yyyy').format(_endDate)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Visual Trends Dashboard',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0A74DA)),
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Image(image, height: 260, fit: pw.BoxFit.contain),
              ),
              if (tableData.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'Raw Parameter Log Records',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0A74DA)),
                ),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['Date', 'Time', 'Type', 'Parameter', 'Value', 'Unit'],
                  data: tableData,
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A74DA)),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  cellDecoration: (int index, dynamic data, int rowNum) {
                    return pw.BoxDecoration(
                      color: rowNum % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                    );
                  },
                ),
              ] else ...[
                pw.SizedBox(height: 20),
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No parameter records logged for this date range.',
                    style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        );

        final path = '${directory.path}/PondStat_Report_$dateSuffix.pdf';
        final file = File(path);
        await file.writeAsBytes(await pdf.save());

        final result = await SharePlus.instance.share(
          ShareParams(files: [XFile(path)], text: 'PondStat Parameter PDF Report'),
        );

        if (result.status == ShareResultStatus.success) {
          if (!context.mounted) return;
          SnackbarHelper.showSuccess(context, "PDF exported successfully!");
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackbarHelper.showError(context, "Failed to export report: $e");
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
          preferredSize: const Size.fromHeight(80.0),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
            child: TabBar(
              isScrollable: false,
              labelColor: const Color(0xFF0A74DA),
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: const Color(0xFF0A74DA),
              labelPadding: const EdgeInsets.symmetric(vertical: 14.0),
              tabs: const [
                Tab(text: "Daily"),
                Tab(text: "Weekly"),
                Tab(text: "Biweekly"),
                Tab(text: "Final"),
              ],
            ),
          ),
        ),
        body: RepaintBoundary(
          key: _boundaryKey,
          child: Column(
            children: [
              _buildDateRangeSelector(context),
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
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
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
    );
  }
}
