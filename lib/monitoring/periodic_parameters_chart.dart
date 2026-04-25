import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'monitoring_parameters.dart';
import '../firebase/firestore_helper.dart';

class _DailyRecord {
  final DateTime timestamp;
  final double averageValue;
  final Map<String, double> pointValues;
  const _DailyRecord({
    required this.timestamp,
    required this.averageValue,
    required this.pointValues,
  });
}

class PeriodicParametersChart extends StatefulWidget {
  final String pondId;
  final String species;
  final String type;
  const PeriodicParametersChart({
    super.key,
    required this.pondId,
    required this.species,
    required this.type,
  });

  @override
  State<PeriodicParametersChart> createState() => _PeriodicParametersChartState();
}

class _PeriodicParametersChartState extends State<PeriodicParametersChart>
    with SingleTickerProviderStateMixin {
  late final List<ParameterItem> _params;
  int _selectedIndex = 0;

  // FIX 1: Cache the active stream so it is not recreated on every build/setState.
  Stream<List<_DailyRecord>>? _cachedStream;
  int _cachedStreamIndex = -1; // tracks which param the cached stream belongs to

  @override
  void initState() {
    super.initState();
    List<ParameterItem> paramsToUse;
    if (widget.type == 'weekly') {
      paramsToUse = MonitoringParameters.weeklyParameters;
    } else if (widget.type == 'biweekly') {
      paramsToUse = MonitoringParameters.biweeklyParameters;
    } else {
      paramsToUse = MonitoringParameters.getDailyParameters(widget.species);
    }
    
    _params = [
      ...paramsToUse.where((p) => p.isSinglePoint),
      ...paramsToUse.where((p) => !p.isSinglePoint),
    ];
    final firstRangeIdx = _params.indexWhere((p) => !p.isSinglePoint);
    if (firstRangeIdx != -1) _selectedIndex = firstRangeIdx;
  }

  /// Returns the cached stream, only rebuilding it when the selected parameter changes.
  Stream<List<_DailyRecord>> _getStream(int index) {
    if (_cachedStream != null && _cachedStreamIndex == index) {
      return _cachedStream!;
    }
    final param = _params[index];
    _cachedStreamIndex = index;
    _cachedStream = FirestoreHelper.measurementsCollection
        .where('pondId', isEqualTo: widget.pondId)
        .where('type', isEqualTo: widget.type)
        .where('parameter', isEqualTo: param.label)
        .orderBy('timestamp', descending: true)  // descending avoids limitToLast index
        .limit(30)
        .snapshots()
        .map((snap) {
          // Reverse so chart renders oldest → newest (left → right)
          final docs = snap.docs.reversed.toList();
          return docs.map((doc) {
              final data = doc.data();
              final ts =
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
              // field is 'value', not 'averageValue'
              final avg = (data['value'] as num?)?.toDouble() ?? 0.0;
              final rawPoints =
                  (data['pointValues'] as Map<String, dynamic>?) ?? {};
              final points = rawPoints
                  .map((k, v) => MapEntry(k, (v as num).toDouble()));
              return _DailyRecord(
                timestamp: ts,
                averageValue: avg,
                pointValues: points,
              );
            }).toList();
        });
    return _cachedStream!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme),
        const SizedBox(height: 12),
        _buildParamTabBar(theme, isDark),
        const SizedBox(height: 16),
        _buildChartArea(theme, isDark),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.show_chart_rounded,
                color: theme.colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            widget.type == 'daily'
                ? 'Daily Trends'
                : widget.type == 'weekly'
                    ? 'Weekly Trends'
                    : 'Biweekly Trends',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Last 30 readings',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamTabBar(ThemeData theme, bool isDark) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _params.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedIndex;
          final param = _params[i];
          return GestureDetector(
            onTap: () {
              if (_selectedIndex != i) {
                setState(() {
                  _selectedIndex = i;
                  // Invalidate cache so _getStream() rebuilds for new param
                  _cachedStream = null;
                  _cachedStreamIndex = -1;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? param.color
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: param.color.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(param.icon,
                      size: 14,
                      color: selected
                          ? Colors.white
                          : (isDark
                              ? Colors.white54
                              : Colors.grey.shade600)),
                  const SizedBox(width: 6),
                  Text(
                    param.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? Colors.white
                          : (isDark
                              ? Colors.white54
                              : Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartArea(ThemeData theme, bool isDark) {
    final param = _params[_selectedIndex];
    return StreamBuilder<List<_DailyRecord>>(
      // FIX 1: use cached stream instead of calling _recordsStream() directly
      stream: _getStream(_selectedIndex),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(isDark, param.color);
        }
        if (snap.hasError) return _buildErrorCard(snap.error.toString(), isDark);
        final records = snap.data ?? [];
        if (records.isEmpty) return _buildEmptyCard(param, isDark);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildStatRow(records, param, theme, isDark),
              const SizedBox(height: 16),
              _buildCard(
                  isDark: isDark,
                  color: param.color,
                  child: _buildLineChart(records, param, isDark)),
              if (!param.isSinglePoint &&
                  (param.minVal != null || param.maxVal != null)) ...[
                const SizedBox(height: 8),
                _buildRangeLegend(param, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(List<_DailyRecord> records, ParameterItem param,
      ThemeData theme, bool isDark) {
    final values = records.map((r) => r.averageValue).toList();
    final latest = values.last;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unit = param.unit.isEmpty ? '' : ' ${param.unit}';
    return Row(
      children: [
        _buildStatChip(
            label: 'Latest',
            value: '${latest.toStringAsFixed(2)}$unit',
            color: param.color,
            isDark: isDark,
            isHighlighted: true),
        const SizedBox(width: 8),
        _buildStatChip(
            label: 'Avg',
            value: '${avg.toStringAsFixed(2)}$unit',
            color: param.color,
            isDark: isDark),
        const SizedBox(width: 8),
        _buildStatChip(
            label: 'Min',
            value: '${min.toStringAsFixed(2)}$unit',
            color: param.color,
            isDark: isDark),
        const SizedBox(width: 8),
        _buildStatChip(
            label: 'Max',
            value: '${max.toStringAsFixed(2)}$unit',
            color: param.color,
            isDark: isDark),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withValues(alpha: 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isHighlighted
                        ? color
                        : (isDark ? Colors.white38 : Colors.grey.shade500),
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isHighlighted
                        ? color
                        : (isDark ? Colors.white70 : Colors.grey.shade800)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
      List<_DailyRecord> records, ParameterItem param, bool isDark) {
    final spots = records
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.averageValue))
        .toList();
    final values = records.map((r) => r.averageValue).toList();
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (param.minVal != null && param.minVal! < minY) minY = param.minVal!;
    if (param.maxVal != null && param.maxVal! > maxY) maxY = param.maxVal!;
    final yPad = ((maxY - minY) * 0.15).clamp(0.5, double.infinity);
    minY -= yPad;
    maxY += yPad;
    final labelColor = isDark ? Colors.white38 : Colors.grey.shade500;
    final gridColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.grey.shade200;

    List<HorizontalLine> extraLines = [];
    if (param.minVal != null) {
      extraLines.add(HorizontalLine(
        y: param.minVal!,
        color: Colors.green.withValues(alpha: 0.6),
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          style: TextStyle(
              color: Colors.green.shade600,
              fontWeight: FontWeight.w700,
              fontSize: 10),
          labelResolver: (line) => 'Min ${line.y}',
        ),
      ));
    }
    if (param.maxVal != null) {
      extraLines.add(HorizontalLine(
        y: param.maxVal!,
        color: Colors.red.withValues(alpha: 0.6),
        strokeWidth: 1.5,
        dashArray: [6, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          padding: const EdgeInsets.only(right: 4, bottom: 2),
          style: TextStyle(
              color: Colors.red.shade400,
              fontWeight: FontWeight.w700,
              fontSize: 10),
          labelResolver: (line) => 'Max ${line.y}',
        ),
      ));
    }

    return SizedBox(
      height: 220,
      child: LineChart(LineChartData(
        minX: 0,
        maxX: (records.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        extraLinesData: ExtraLinesData(horizontalLines: extraLines),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(_formatAxisValue(value),
                      style: TextStyle(
                          color: labelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600),
                      textAlign: TextAlign.right),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _xInterval(records.length),
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= records.length) {
                  return const SizedBox.shrink();
                }
                final dt = records[idx].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text('${dt.month}/${dt.day}',
                      style: TextStyle(
                          color: labelColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                isDark ? const Color(0xFF1E293B) : Colors.white,
            tooltipBorder:
                BorderSide(color: param.color.withValues(alpha: 0.3)),
            tooltipBorderRadius: BorderRadius.circular(12),
            getTooltipItems: (spots) => spots.map((s) {
              final record = records[s.spotIndex];
              final dt = record.timestamp;
              final unit = param.unit.isEmpty ? '' : ' ${param.unit}';
              return LineTooltipItem(
                '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n${s.y.toStringAsFixed(2)}$unit',
                TextStyle(
                    color: param.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: param.color,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: records.length <= 15,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                  radius: 3.5,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: param.color),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  param.color.withValues(alpha: 0.22),
                  param.color.withValues(alpha: 0.0)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildRangeLegend(ParameterItem param, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (param.minVal != null) ...[
          _legendDash(Colors.green),
          const SizedBox(width: 4),
          Text(
              'Min ${param.minVal}${param.unit.isEmpty ? '' : ' ${param.unit}'}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade600)),
          const SizedBox(width: 16),
        ],
        if (param.maxVal != null) ...[
          _legendDash(Colors.red),
          const SizedBox(width: 4),
          Text(
              'Max ${param.maxVal}${param.unit.isEmpty ? '' : ' ${param.unit}'}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey.shade600)),
        ],
      ],
    );
  }

  Widget _legendDash(Color color) => Container(
      width: 20,
      height: 2,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(2)));

  Widget _buildLoadingCard(bool isDark, Color color) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCard(
          isDark: isDark,
          color: color,
          child: const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)))));

  Widget _buildEmptyCard(ParameterItem param, bool isDark) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildCard(
        isDark: isDark,
        color: param.color,
        child: SizedBox(
          height: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 48, color: param.color.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text('No data recorded yet',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDark ? Colors.white54 : Colors.grey.shade600)),
              const SizedBox(height: 6),
              Text(
                  'Record your first ${param.label} measurement\nto see the trend here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      height: 1.4)),
            ],
          ),
        ),
      ));

  Widget _buildErrorCard(String error, bool isDark) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20)),
        child: Text('Failed to load data:\n$error',
            style: const TextStyle(color: Colors.red, fontSize: 13),
            textAlign: TextAlign.center),
      ));

  Widget _buildCard(
          {required bool isDark,
          required Color color,
          required Widget child}) =>
      Container(
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isDark ? Border.all(color: Colors.white12) : null,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 6))
            ],
          ),
          child: child);

  String _formatAxisValue(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  double _xInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 15) return 3;
    return 5;
  }
}