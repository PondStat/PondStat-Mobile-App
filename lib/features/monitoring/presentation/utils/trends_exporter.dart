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
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
import 'package:pondstat/features/monitoring/data/finances_repository.dart';
import 'package:pondstat/core/services/safety/safety_evaluator.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class FinanceTransaction {
  final DateTime date;
  final String type; // 'Group Expense', 'Direct Expense', 'Sale'
  final String item;
  final double quantity;
  final String unit;
  final double amountPerUnit;
  final double totalAmount;

  FinanceTransaction({
    required this.date,
    required this.type,
    required this.item,
    required this.quantity,
    required this.unit,
    required this.amountPerUnit,
    required this.totalAmount,
  });
}

class TrendsExporter {
  /// Captures the widget subtree under [boundaryKey] as raw PNG bytes.
  static Future<Uint8List?> capturePng(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
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

  /// Formats and exports a report in the specified [format] ('csv', 'image', or 'pdf') and opens the native share sheet.
  static Future<void> exportReport({
    required BuildContext context,
    required String format,
    required MonitoringRepository monitoringRepo,
    required GrowthRepository growthRepo,
    required FinancesRepository financesRepo,
    required String pondName,
    required GlobalKey boundaryKey,
    required String pondId,
    required String species,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    SnackbarHelper.showInfo(context, "Generating ${format.toUpperCase()} report...");
    final directory = await getTemporaryDirectory();
    final dateSuffix = DateFormat('yyyyMMdd').format(DateTime.now());

    if (format == 'csv') {
      final querySnapshot = await monitoringRepo.getMeasurementsByDateRange(
        pondId,
        startDate,
        endDate,
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
        final type = data['type']?.toString() ?? 'NA';
        final parameter = data['parameter']?.toString() ?? 'NA';
        final value = data['value']?.toString() ?? 'NA';
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
      final capturedBytes = await capturePng(boundaryKey);
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
      final capturedBytes = await capturePng(boundaryKey);
      if (capturedBytes == null) {
        if (!context.mounted) return;
        SnackbarHelper.showError(context, "Failed to capture chart image for PDF.");
        return;
      }

      // ─── 1. Query Water Quality Data ───────────────────────────────
      final querySnapshot = await monitoringRepo.getMeasurementsByDateRange(
        pondId,
        startDate,
        endDate,
      ).get();

      final evaluator = SafetyEvaluator();
      int warningAlertCount = 0;
      int criticalAlertCount = 0;
      int totalWQReadings = 0;

      final Map<String, List<double>> wqParamsValues = {};
      final Map<String, int> wqParamsOutliers = {};
      final Map<String, String> wqParamsUnits = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final type = data['type']?.toString();
        if (type == 'growth') continue;

        final paramLabel = data['parameter']?.toString() ?? 'Unknown';
        final val = (data['value'] as num?)?.toDouble();
        final unit = data['unit']?.toString() ?? '';
        if (val == null) continue;

        totalWQReadings++;
        wqParamsValues.putIfAbsent(paramLabel, () => []).add(val);
        wqParamsUnits[paramLabel] = unit;

        // Evaluate alerts
        var tierStr = '';
        if (data['alert'] != null) {
          final alertMap = data['alert'] as Map<String, dynamic>;
          tierStr = alertMap['tier']?.toString() ?? '';
        } else {
          final paramItem = MonitoringParameters.getParameterByLabel(paramLabel, species);
          if (paramItem != null) {
            final eval = evaluator.evaluate(paramItem, val);
            if (eval != null) {
              tierStr = eval.tier.toString();
            }
          }
        }

        if (tierStr.isNotEmpty) {
          final t = tierStr.toLowerCase();
          if (t.contains('critical')) {
            criticalAlertCount++;
            wqParamsOutliers[paramLabel] = (wqParamsOutliers[paramLabel] ?? 0) + 1;
          } else if (t.contains('warning')) {
            warningAlertCount++;
            wqParamsOutliers[paramLabel] = (wqParamsOutliers[paramLabel] ?? 0) + 1;
          }
        }
      }

      final List<List<String>> wqTableData = [];
      for (var entry in wqParamsValues.entries) {
        final paramName = entry.key;
        final values = entry.value;
        final unit = wqParamsUnits[paramName] ?? '';
        final outliers = wqParamsOutliers[paramName] ?? 0;

        final double avg = values.reduce((a, b) => a + b) / values.length;
        final double min = values.reduce((a, b) => a < b ? a : b);
        final double max = values.reduce((a, b) => a > b ? a : b);

        wqTableData.add([
          paramName,
          unit,
          avg.toStringAsFixed(1),
          min.toStringAsFixed(1),
          max.toStringAsFixed(1),
          outliers.toString(),
        ]);
      }
      wqTableData.sort((a, b) => a[0].compareTo(b[0]));

      // ─── 2. Query Growth Data ──────────────────────────────────────
      final allGrowthMetrics = await growthRepo.calculateGrowthMetrics(pondId);
      final filteredGrowth = allGrowthMetrics.where((m) {
        return m.date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
               m.date.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
      filteredGrowth.sort((a, b) => a.date.compareTo(b.date));

      double? startAbw;
      double? endAbw;
      double sumAdg = 0.0;
      int adgCount = 0;

      for (var m in filteredGrowth) {
        if (m.abw != null) {
          startAbw ??= m.abw;
          endAbw = m.abw;
        }
        if (m.adg != null) {
          sumAdg += m.adg!;
          adgCount++;
        }
      }
      final double? avgAdg = adgCount > 0 ? sumAdg / adgCount : null;

      final List<List<String>> growthTableData = [];
      for (var m in filteredGrowth) {
        final dateStr = DateFormat('yyyy-MM-dd').format(m.date);
        growthTableData.add([
          'Week ${m.weekNumber}',
          dateStr,
          m.abw != null ? '${m.abw} g' : '-',
          m.adg != null ? '${m.adg} g/d' : '-',
          m.fcr != null ? m.fcr!.toStringAsFixed(2) : '-',
          m.dfr != null ? '${m.dfr} kg/d' : '-',
          m.feedConsumed > 0 ? '${m.feedConsumed} kg' : '-',
          m.notes ?? '',
        ]);
      }

      // ─── 3. Query Finances Data ────────────────────────────────────
      final source = financesRepo.isOffline() ? Source.cache : Source.serverAndCache;

      final groupExpSnap = await financesRepo.expensesCollection
          .where('pondId', isEqualTo: pondId)
          .get(GetOptions(source: source));

      final directExpSnap = await financesRepo.pondExpensesCollection
          .where('pondId', isEqualTo: pondId)
          .get(GetOptions(source: source));

      final salesSnap = await financesRepo.pondSalesCollection
          .where('pondId', isEqualTo: pondId)
          .get(GetOptions(source: source));

      final List<FinanceTransaction> transactions = [];
      double totalGroupExp = 0.0;
      double totalDirectExp = 0.0;
      double totalSales = 0.0;

      bool isWithinRange(DateTime dt) {
        return dt.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
               dt.isBefore(endDate.add(const Duration(days: 1)));
      }

      for (var doc in groupExpSnap.docs) {
        final data = doc.data();
        final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (!isWithinRange(date)) continue;

        final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalGroupExp += total;

        transactions.add(FinanceTransaction(
          date: date,
          type: 'Group Expense',
          item: data['item']?.toString() ?? 'Group Expense',
          quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
          unit: 'pcs',
          amountPerUnit: (data['amountPerItem'] as num?)?.toDouble() ?? 0.0,
          totalAmount: total,
        ));
      }

      for (var doc in directExpSnap.docs) {
        final data = doc.data();
        final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (!isWithinRange(date)) continue;

        final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalDirectExp += total;

        transactions.add(FinanceTransaction(
          date: date,
          type: 'Direct Expense',
          item: '${data['category'] ?? 'Expense'}: ${data['item'] ?? ''}',
          quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
          unit: data['unit']?.toString() ?? 'pcs',
          amountPerUnit: (data['amountPerUnit'] as num?)?.toDouble() ?? 0.0,
          totalAmount: total,
        ));
      }

      for (var doc in salesSnap.docs) {
        final data = doc.data();
        final date = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        if (!isWithinRange(date)) continue;

        final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
        totalSales += total;

        transactions.add(FinanceTransaction(
          date: date,
          type: 'Sale',
          item: '${data['productName'] ?? 'Sale'} to ${data['buyerName'] ?? ''}',
          quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
          unit: data['unit']?.toString() ?? 'pcs',
          amountPerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
          totalAmount: total,
        ));
      }

      transactions.sort((a, b) => a.date.compareTo(b.date));

      final double totalExpenses = totalGroupExp + totalDirectExp;
      final double netProfit = totalSales - totalExpenses;

      final List<List<String>> financeTableData = [];
      for (var tx in transactions) {
        final dateStr = DateFormat('yyyy-MM-dd').format(tx.date);
        financeTableData.add([
          dateStr,
          tx.type,
          tx.item,
          tx.quantity.toStringAsFixed(1),
          tx.unit,
          '\$${tx.amountPerUnit.toStringAsFixed(2)}',
          '\$${tx.totalAmount.toStringAsFixed(2)}',
        ]);
      }

      // ─── 4. PDF Setup & Render ─────────────────────────────────────
      final pdf = pw.Document();
      final chartImage = pw.MemoryImage(capturedBytes);

      // Section helper widgets
      pw.Widget buildSectionHeader(String title) {
        return pw.Container(
          margin: const pw.EdgeInsets.only(top: 20, bottom: 8),
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF0A74DA), width: 1.5)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: const PdfColor.fromInt(0xFF0A74DA),
            ),
          ),
        );
      }

      pw.Widget buildKpiCard({required String title, required List<pw.Widget> children, PdfColor? borderColor}) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: borderColor ?? PdfColors.grey300, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 6),
              ...children,
            ],
          ),
        );
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
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Pond Name: $pondName',
                    style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    'PondStat Operational Report',
                    style: pw.TextStyle(color: PdfColors.grey500, fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                ],
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
          build: (pw.Context context) {
            final wqHealthColor = criticalAlertCount > 0
                ? const PdfColor.fromInt(0xFFE53935)
                : (warningAlertCount > 0
                    ? const PdfColor.fromInt(0xFFFFB300)
                    : const PdfColor.fromInt(0xFF4CAF50));

            return [
              // Cover Title Block
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
                      pw.Text('Pond ID: $pondId', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      pw.Text('Species: $species', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Date Range Indicator
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
                      '${DateFormat('MMMM d, yyyy').format(startDate)} - ${DateFormat('MMMM d, yyyy').format(endDate)}',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // KPI Dashboard row
              pw.Text(
                'Operational Summary Dashboard',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0A74DA)),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: buildKpiCard(
                      title: 'WATER QUALITY HEALTH',
                      borderColor: wqHealthColor,
                      children: [
                        pw.Text('Total Readings: $totalWQReadings', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Warning Alerts: $warningAlertCount', style: pw.TextStyle(fontSize: 9, fontWeight: warningAlertCount > 0 ? pw.FontWeight.bold : pw.FontWeight.normal)),
                        pw.Text('Critical Alerts: $criticalAlertCount', style: pw.TextStyle(fontSize: 9, fontWeight: criticalAlertCount > 0 ? pw.FontWeight.bold : pw.FontWeight.normal)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: buildKpiCard(
                      title: 'STOCK GROWTH',
                      children: [
                        pw.Text('Start ABW: ${startAbw != null ? "$startAbw g" : "N/A"}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('End ABW: ${endAbw != null ? "$endAbw g" : "N/A"}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Avg ADG: ${avgAdg != null ? "${avgAdg.toStringAsFixed(2)} g/d" : "N/A"}', style: const pw.TextStyle(fontSize: 9)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: buildKpiCard(
                      title: 'CROP FINANCES',
                      children: [
                        pw.Text('Expenses: \$${totalExpenses.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Sales: \$${totalSales.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text(
                          'Net Profit: \$${netProfit.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: netProfit >= 0 ? const PdfColor.fromInt(0xFF4CAF50) : const PdfColor.fromInt(0xFFE53935),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.NewPage(),

              // Page 2: Water Quality Trends & Statistics Table
              buildSectionHeader('Water Quality Trends'),
              pw.SizedBox(height: 8),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Image(chartImage, height: 240, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Water Quality Parameters Statistics',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF0A74DA)),
              ),
              pw.SizedBox(height: 8),
              if (wqTableData.isNotEmpty) ...[
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['Parameter', 'Unit', 'Average', 'Min', 'Max', 'Outliers'],
                  data: wqTableData,
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
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No water quality parameters logged for this date range.',
                    style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],

              pw.NewPage(),

              // Page 3: Stock Growth Metrics
              buildSectionHeader('Stock Growth Performance'),
              pw.SizedBox(height: 8),
              if (growthTableData.isNotEmpty) ...[
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['Week', 'Sampling Date', 'ABW', 'ADG', 'FCR', 'DFR', 'Feed Consumed', 'Notes'],
                  data: growthTableData,
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A74DA)),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  cellDecoration: (int index, dynamic data, int rowNum) {
                    return pw.BoxDecoration(
                      color: rowNum % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                    );
                  },
                ),
              ] else ...[
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No growth metrics logged for this date range.',
                    style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],

              pw.NewPage(),

              // Page 4: Crop Finances Ledger
              buildSectionHeader('Financial Transactions Ledger'),
              pw.SizedBox(height: 8),
              if (financeTableData.isNotEmpty) ...[
                pw.TableHelper.fromTextArray(
                  context: context,
                  headers: ['Date', 'Type', 'Description', 'Qty', 'Unit', 'Rate', 'Total'],
                  data: financeTableData,
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0A74DA)),
                  cellAlignment: pw.Alignment.centerLeft,
                  cellStyle: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  cellDecoration: (int index, dynamic data, int rowNum) {
                    return pw.BoxDecoration(
                      color: rowNum % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                    );
                  },
                ),
              ] else ...[
                pw.Container(
                  alignment: pw.Alignment.center,
                  padding: const pw.EdgeInsets.all(16),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(
                    'No financial transactions recorded for this date range.',
                    style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10, fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ];
          },
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
  }
}
