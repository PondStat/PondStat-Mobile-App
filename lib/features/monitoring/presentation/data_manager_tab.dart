import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:pondstat/core/services/safety/safety_evaluator.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:intl/intl.dart';

class DataManagerTab extends ConsumerStatefulWidget {
  final String pondId;
  final String pondName;
  final String userRole;
  final bool canEdit;

  const DataManagerTab({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.userRole,
    required this.canEdit,
  });

  @override
  ConsumerState<DataManagerTab> createState() => _DataManagerTabState();
}

class _DataManagerTabState extends ConsumerState<DataManagerTab> {
  bool _isExporting = false;
  bool _isImporting = false;

  String getParameterType(String label, String species) {
    final cleanLabel = label.trim().toLowerCase();
    final cleanSpecies = species.trim().toLowerCase();

    // Check daily
    final daily = MonitoringParameters.getDailyParameters(cleanSpecies);
    if (daily.any((p) => p.label.toLowerCase() == cleanLabel)) {
      return 'daily';
    }
    // Check weekly
    final weekly = MonitoringParameters.getWeeklyParameters(cleanSpecies);
    if (weekly.any((p) => p.label.toLowerCase() == cleanLabel)) {
      return 'weekly';
    }
    // Check biweekly
    final biweekly = MonitoringParameters.getBiweeklyParameters(cleanSpecies);
    if (biweekly.any((p) => p.label.toLowerCase() == cleanLabel)) {
      return 'biweekly';
    }
    // Check growth
    final growth = MonitoringParameters.samplingParameters;
    if (growth.any((p) => p.label.toLowerCase() == cleanLabel)) {
      return 'growth';
    }
    return 'daily'; // fallback for custom/unrecognized parameters
  }

  Future<void> _exportData() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final monitoringRepo = ref.read(monitoringRepositoryProvider);
      final source = monitoringRepo.isOffline() ? Source.cache : Source.serverAndCache;

      // Query all measurements for this pond
      final querySnapshot = await monitoringRepo.measurementsCollection
          .where('pondId', isEqualTo: widget.pondId)
          .get(GetOptions(source: source));

      if (querySnapshot.docs.isEmpty) {
        if (mounted) {
          SnackbarHelper.showInfo(context, "No measurements data to export.");
        }
        return;
      }

      List<List<dynamic>> rows = [
        ["Date", "Time", "Type", "Parameter", "Value", "Unit", "Notes"],
      ];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final dateStr = DateFormat('yyyy-MM-dd').format(ts);
        final timeStr = data['timeString']?.toString() ?? DateFormat('HH:mm').format(ts);
        final type = data['type']?.toString() ?? 'daily';
        final parameter = data['parameter']?.toString() ?? 'Unknown';
        final value = data['value']?.toString() ?? '';
        final unit = data['unit']?.toString() ?? '';
        final notes = data['notes']?.toString() ?? '';

        rows.add([dateStr, timeStr, type, parameter, value, unit, notes]);
      }

      final csvData = csv.encode(rows);
      final directory = await getTemporaryDirectory();
      final dateSuffix = DateFormat('yyyyMMdd').format(DateTime.now());
      final path = '${directory.path}/${widget.pondName.replaceAll(' ', '_')}_Export_$dateSuffix.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path)],
          text: 'PondStat Data Export: ${widget.pondName}',
        ),
      );

      if (result.status == ShareResultStatus.success && mounted) {
        SnackbarHelper.showSuccess(context, "Spreadsheet exported successfully!");
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Failed to export data: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _importData() async {
    if (!widget.canEdit) {
      SnackbarHelper.showError(context, "Only owners and editors can import data.");
      return;
    }

    if (_isImporting) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      setState(() => _isImporting = true);

      final file = File(result.files.single.path!);
      final input = await file.readAsString();
      final rows = csv.decode(input);

      if (rows.isEmpty) {
        if (mounted) {
          SnackbarHelper.showError(context, "The selected CSV file is empty.");
        }
        setState(() => _isImporting = false);
        return;
      }

      // Filter empty rows
      final cleanRows = rows.where((r) => r.isNotEmpty && r.any((c) => c.toString().trim().isNotEmpty)).toList();

      if (cleanRows.length <= 1) {
        if (mounted) {
          SnackbarHelper.showError(context, "No record rows detected in CSV.");
        }
        setState(() => _isImporting = false);
        return;
      }

      // Read headers and match columns
      final headers = cleanRows.first.map((h) => h.toString().trim().toLowerCase()).toList();
      final dateIndex = headers.indexWhere((h) => h.contains('date') || h.contains('timestamp'));
      final timeIndex = headers.indexWhere((h) => h.contains('time'));
      final paramIndex = headers.indexWhere((h) => h.contains('parameter') || h.contains('label') || h.contains('name'));
      final valueIndex = headers.indexWhere((h) => h.contains('value') || h.contains('reading'));
      final unitIndex = headers.indexWhere((h) => h.contains('unit'));
      final notesIndex = headers.indexWhere((h) => h.contains('notes') || h.contains('comment'));

      if (dateIndex == -1 || paramIndex == -1 || valueIndex == -1) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            "Required headers missing. CSV must contain 'Date', 'Parameter', and 'Value' columns.",
          );
        }
        setState(() => _isImporting = false);
        return;
      }

      // Fetch pond species once
      final pondDoc = await ref.read(pondRepositoryProvider).pondsCollection.doc(widget.pondId).get();
      final species = pondDoc.data()?.species ?? 'Tilapia';
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid ?? 'unknown';
      final userName = currentUser?.displayName ?? 'Unknown User';

      List<Map<String, dynamic>> recordsToImport = [];
      int skippedCount = 0;

      for (int i = 1; i < cleanRows.length; i++) {
        final row = cleanRows[i];
        if (row.length <= dateIndex || row.length <= paramIndex || row.length <= valueIndex) {
          skippedCount++;
          continue;
        }

        final rawDate = row[dateIndex]?.toString().trim();
        final rawParam = row[paramIndex]?.toString().trim();
        final rawValue = row[valueIndex]?.toString().trim();

        if (rawDate == null || rawParam == null || rawValue == null || rawDate.isEmpty || rawParam.isEmpty || rawValue.isEmpty) {
          skippedCount++;
          continue;
        }

        final rawTime = timeIndex != -1 && row.length > timeIndex ? row[timeIndex]?.toString().trim() ?? '' : '';

        DateTime parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
        String timeString = '00:00';
        if (rawTime.isNotEmpty) {
          final timeParts = rawTime.split(':');
          if (timeParts.length >= 2) {
            final hour = int.tryParse(timeParts[0]);
            final minute = int.tryParse(timeParts[1]);
            if (hour != null && minute != null) {
              parsedDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day, hour, minute);
              timeString = "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}";
            }
          }
        }

        final parsedValue = double.tryParse(rawValue);

        if (parsedValue == null) {
          skippedCount++;
          continue;
        }

        final unitStr = unitIndex != -1 && row.length > unitIndex ? row[unitIndex]?.toString().trim() ?? '' : '';
        final notesStr = notesIndex != -1 && row.length > notesIndex ? row[notesIndex]?.toString().trim() ?? '' : '';

        final type = getParameterType(rawParam, species);
        final paramItem = MonitoringParameters.getParameterByLabel(rawParam, species);

        Map<String, dynamic>? alertMap;
        if (paramItem != null) {
          final eval = SafetyEvaluator().evaluate(paramItem, parsedValue);
          if (eval != null) {
            alertMap = {
              'tier': eval.tier.toString().split('.').last,
              'title': '${paramItem.label} Alert',
              'body': '${paramItem.label} is ${eval.direction.toString().split('.').last} optimal threshold: $parsedValue ${paramItem.unit}',
            };
          }
        }

        final dateKey = "${parsedDate.year}-${parsedDate.month}-${parsedDate.day}";
        final String docId = "${widget.pondId}_${rawParam.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_${dateKey}_$type";

        final recordData = {
          'pondId': widget.pondId,
          'dateKey': dateKey,
          'timestamp': Timestamp.fromDate(parsedDate),
          'timeString': timeString,
          'recordedAt': FieldValue.serverTimestamp(),
          'recordedBy': userId,
          'recorderName': userName,
          'type': type,
          'parameter': rawParam,
          'value': parsedValue,
          'unit': unitStr,
          'notes': notesStr.isNotEmpty ? notesStr : null,
          'alert': alertMap,
        }..removeWhere((key, value) => value == null);

        recordsToImport.add({
          'docId': docId,
          'data': recordData,
        });
      }

      if (recordsToImport.isEmpty) {
        if (mounted) {
          SnackbarHelper.showError(context, "No valid measurement records found to import.");
        }
        setState(() => _isImporting = false);
        return;
      }

      if (mounted) {
        _showConfirmationDialog(recordsToImport, skippedCount);
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Failed to parse CSV file: $e");
      }
      setState(() => _isImporting = false);
    }
  }

  void _showConfirmationDialog(List<Map<String, dynamic>> records, int skipped) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            "Confirm CSV Import",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Verify import details before committing to the database:",
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Valid Rows to Import: ${records.length}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              if (skipped > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Skipped/Invalid Rows: $skipped",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                setState(() => _isImporting = false);
              },
              child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _executeImport(records);
              },
              child: const Text("Import Now", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _executeImport(List<Map<String, dynamic>> records) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show loading progress overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      "Importing records... Please do not close the app.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final monitoringRepo = ref.read(monitoringRepositoryProvider);
      final currentUser = FirebaseAuth.instance.currentUser;
      final userId = currentUser?.uid ?? 'unknown';
      final userName = currentUser?.displayName ?? 'Unknown User';

      // 500 limits on batch operations, under chunk size 200 is extremely safe
      const int chunkSize = 200;
      for (var i = 0; i < records.length; i += chunkSize) {
        final chunk = records.sublist(
          i,
          i + chunkSize > records.length ? records.length : i + chunkSize,
        );

        final batch = firestore.batch();
        for (var record in chunk) {
          final String docId = record['docId'];
          final ref = monitoringRepo.measurementsCollection.doc(docId);
          batch.set(ref, record['data']);
        }
        await batch.commit();
      }

      // Log bulk action to history
      await monitoringRepo.measurementHistoryCollection.add({
        'pondId': widget.pondId,
        'parameter': 'Bulk Import',
        'action': 'create',
        'editedAt': FieldValue.serverTimestamp(),
        'editedBy': userId,
        'editorName': userName,
        'before': null,
        'after': {'value': 'Bulk imported ${records.length} records from CSV'},
      });

      if (mounted) {
        // Pop loading overlay
        Navigator.of(context).pop();
        SnackbarHelper.showSuccess(context, "Successfully imported ${records.length} measurements!");
      }
    } catch (e) {
      if (mounted) {
        // Pop loading overlay
        Navigator.of(context).pop();
        SnackbarHelper.showError(context, "Bulk import failed: $e");
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    Widget buildCard({
      required String title,
      required String subtitle,
      required String description,
      required IconData icon,
      required Color iconColor,
      required Widget action,
      Widget? preview,
    }) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : colorScheme.outlineVariant,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (preview != null) ...[
              const SizedBox(height: 16),
              preview,
            ],
            const SizedBox(height: 16),
            action,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        children: [
          // Card 1: Bulk Export Data
          buildCard(
            title: "Export All Data",
            subtitle: "Download crop backups & log logs",
            description:
                "Generates a universal CSV spreadsheet containing all logged measurements, dates, times, parameters, values, units, and notes for this pond. This helps prevent vendor lock-in and allows analysis in Microsoft Excel or Google Sheets.",
            icon: Icons.file_download_outlined,
            iconColor: const Color(0xFF0A74DA),
            action: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A74DA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isExporting ? null : _exportData,
                icon: _isExporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded, size: 20),
                label: Text(
                  _isExporting ? "Exporting Data..." : "Export Pond Data to CSV",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Card 2: Bulk Import Data
          buildCard(
            title: "Bulk Import Spreadsheet",
            subtitle: "Onboard Excel records in seconds",
            description:
                "Upload pond parameters or weekly growth logs from Excel or Google Sheets. Choose a CSV file on your device. The spreadsheet must match the column layout detailed below.",
            icon: Icons.upload_file_rounded,
            iconColor: const Color(0xFF107C41),
            preview: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.03) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "REQUIRED CSV HEADERS & SAMPLE:",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Table(
                      defaultColumnWidth: const FixedColumnWidth(100),
                      border: TableBorder.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5), width: 1),
                      children: const [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.black12),
                          children: [
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Date", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Time", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Parameter", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Value", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Unit", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Notes", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("2026-05-24", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("08:00", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("pH Level", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("7.5", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Morning log", style: TextStyle(fontSize: 9)))),
                          ],
                        ),
                        TableRow(
                          children: [
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("2026-05-24", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("09:00", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("ABW", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("12.4", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("g", style: TextStyle(fontSize: 9)))),
                            TableCell(child: Padding(padding: EdgeInsets.all(6), child: Text("Weekly sampling", style: TextStyle(fontSize: 9)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            action: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF107C41),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isImporting ? null : _importData,
                icon: _isImporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.file_present_rounded, size: 20),
                label: Text(
                  _isImporting ? "Processing CSV..." : "Upload CSV Spreadsheet",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
