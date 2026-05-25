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

      final querySnapshot = await monitoringRepo.getMeasurementsByDateRange(
        pondId,
        startDate,
        endDate,
      ).get();

      final pdf = pw.Document();
      final image = pw.MemoryImage(capturedBytes);

      List<List<String>> tableData = [];
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(ts);
        final timeStr = DateFormat('HH:mm').format(ts);
        final type = data['type']?.toString() ?? 'NA';
        final parameter = data['parameter']?.toString() ?? 'NA';
        final value = data['value']?.toString() ?? 'NA';
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
                    pw.Text('Pond ID: $pondId', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    pw.SizedBox(height: 2),
                    pw.Text('Species: $species', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
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
                    '${DateFormat('MMMM d, yyyy').format(startDate)} - ${DateFormat('MMMM d, yyyy').format(endDate)}',
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
  }
}
