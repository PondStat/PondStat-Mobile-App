import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';

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

class PeriodicParametersChart extends ConsumerStatefulWidget {
  final String pondId;
  final String species;
  final String type;
  final DateTime startDate;
  final DateTime endDate;

  const PeriodicParametersChart({
    super.key,
    required this.pondId,
    required this.species,
    required this.type,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<PeriodicParametersChart> createState() =>
      _PeriodicParametersChartState();
}

class _PeriodicParametersChartState extends ConsumerState<PeriodicParametersChart>
    with SingleTickerProviderStateMixin {
  late final List<ParameterItem> _baseParams;
  int _selectedIndex = 0;

  // Cache the active stream so it is not recreated on every build/setState.
  Stream<List<_DailyRecord>>? _cachedStream;
  String? _cachedStreamParamLabel; // tracks which param the cached stream belongs to
  int? _lastTouchedSpotIndex;

  @override
  void initState() {
    super.initState();
    List<ParameterItem> paramsToUse;
    if (widget.type == 'weekly') {
      paramsToUse = MonitoringParameters.getWeeklyParameters(widget.species);
    } else if (widget.type == 'biweekly') {
      paramsToUse = MonitoringParameters.getBiweeklyParameters(widget.species);
    } else {
      paramsToUse = MonitoringParameters.getDailyParameters(widget.species);
    }

    final excludedParams = [
      'Feeding rate',
      'Total feed consumed',
      'Total weight gained',
      'Total weight of fish sampled',
      'Number of fish sampled',
    ];

    _baseParams = paramsToUse
        .where((p) => !excludedParams.contains(p.label))
        .toList();
    final firstRangeIdx = _baseParams.indexWhere((p) => !p.isSinglePoint);
    if (firstRangeIdx != -1) _selectedIndex = firstRangeIdx;
  }

  @override
  void didUpdateWidget(covariant PeriodicParametersChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _cachedStream = null;
      _cachedStreamParamLabel = null;
    }
  }

  /// Returns the cached stream, only rebuilding it when the selected parameter changes or dates update.
  Stream<List<_DailyRecord>> _getStream(ParameterItem param) {
    if (_cachedStream != null && _cachedStreamParamLabel == param.label) {
      return _cachedStream!;
    }

    _cachedStreamParamLabel = param.label;
    final endOfDay = DateTime(
      widget.endDate.year,
      widget.endDate.month,
      widget.endDate.day,
      23,
      59,
      59,
    );

    _cachedStream = ref.read(monitoringRepositoryProvider).measurementsCollection
        .where('pondId', isEqualTo: widget.pondId)
        .where('type', isEqualTo: widget.type)
        .where('parameter', isEqualTo: param.label)
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(widget.startDate),
        )
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snap) {
          final sortedDocs = snap.docs.toList()
            ..sort((a, b) {
              final tA = a.data()['timestamp'] as Timestamp?;
              final tB = b.data()['timestamp'] as Timestamp?;
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA); // descending
            });

          // Show all items from this date range (in chronological order for the chart)
          final limitedDocs = sortedDocs.reversed.toList();

          return limitedDocs
              .where((doc) => doc.data()['value'] != null)
              .map((doc) {
            final data = doc.data();
            final ts =
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
            final avg = (data['value'] as num).toDouble();
            final rawPoints =
                (data['pointValues'] as Map<String, dynamic>?) ?? {};
            final points = rawPoints.map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            );
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

    return StreamBuilder<QuerySnapshot>(
      stream: ref.read(monitoringRepositoryProvider).customParametersCollection
          .where('type', isEqualTo: widget.type)
          .where('pondId', isEqualTo: widget.pondId)
          .snapshots(),
      builder: (context, snapshot) {
        List<ParameterItem> allParams = List.from(_baseParams);

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            allParams.add(
              ParameterItem(
                label: data['label'],
                unit: data['unit'] ?? '',
                icon: Icons.dashboard_customize_rounded,
                category: ParameterCategory.custom,
                createdBy: data['createdBy'],
              ),
            );
          }
        }

        final params = [
          ...allParams.where((p) => p.isSinglePoint),
          ...allParams.where((p) => !p.isSinglePoint),
        ];

        if (_selectedIndex >= params.length) {
          _selectedIndex = 0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(theme),
            const SizedBox(height: 12),
            _buildParamTabBar(theme, isDark, params),
            const SizedBox(height: 16),
            _buildChartArea(theme, isDark, params),
            const SizedBox(height: 24),
          ],
        );
      },
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
            child: Icon(
              Icons.show_chart_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
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
        ],
      ),
    );
  }

  Widget _buildParamTabBar(
    ThemeData theme,
    bool isDark,
    List<ParameterItem> params,
  ) {
    final colorScheme = theme.colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: params.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final selected = i == _selectedIndex;
          final param = params[i];
          return GestureDetector(
            onTap: () {
              if (_selectedIndex != i) {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedIndex = i;
                  // Invalidate cache so _getStream() rebuilds for new param
                  _cachedStream = null;
                  _cachedStreamParamLabel = null;
                });
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? param.getColor(context)
                    : colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: param
                              .getColor(context)
                              .withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    param.icon,
                    size: 14,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    param.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
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

  Widget _buildChartArea(
    ThemeData theme,
    bool isDark,
    List<ParameterItem> params,
  ) {
    if (params.isEmpty) return const SizedBox.shrink();
    final param = params[_selectedIndex];
    return StreamBuilder<List<_DailyRecord>>(
      // FIX 1: use cached stream instead of calling _recordsStream() directly
      stream: _getStream(param),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard(isDark, param.getColor(context), theme);
        }
        if (snap.hasError) {
          return _buildErrorCard(snap.error.toString(), isDark, theme);
        }
        final records = snap.data ?? [];
        if (records.isEmpty) return _buildEmptyCard(param, isDark, theme);
        if (records.length == 1) {
          return _buildSinglePointCard(records.first, param, isDark, theme);
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _buildStatRow(records, param, theme, isDark),
              const SizedBox(height: 16),
              _buildCard(
                isDark: isDark,
                color: param.getColor(context),
                theme: theme,
                child: _buildLineChart(records, param, isDark, theme),
              ),
              if (!param.isSinglePoint &&
                  (param.optimalMin != null || param.optimalMax != null)) ...[
                const SizedBox(height: 8),
                _buildRangeLegend(param, isDark, theme),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatRow(
    List<_DailyRecord> records,
    ParameterItem param,
    ThemeData theme,
    bool isDark,
  ) {
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
          color: param.getColor(context),
          isDark: isDark,
          theme: theme,
          isHighlighted: true,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          label: 'Avg',
          value: '${avg.toStringAsFixed(2)}$unit',
          color: param.getColor(context),
          isDark: isDark,
          theme: theme,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          label: 'Min',
          value: '${min.toStringAsFixed(2)}$unit',
          color: param.getColor(context),
          isDark: isDark,
          theme: theme,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          label: 'Max',
          value: '${max.toStringAsFixed(2)}$unit',
          color: param.getColor(context),
          isDark: isDark,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    bool isHighlighted = false,
  }) {
    final colorScheme = theme.colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withValues(alpha: 0.12)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isHighlighted ? color : colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? color : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(
    List<_DailyRecord> records,
    ParameterItem param,
    bool isDark,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;
    final spots = records
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.averageValue))
        .toList();
    final values = records.map((r) => r.averageValue).toList();
    double minY = values.reduce((a, b) => a < b ? a : b);
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (param.optimalMin != null && param.optimalMin! < minY) {
      minY = param.optimalMin!;
    }
    if (param.optimalMax != null && param.optimalMax! > maxY) {
      maxY = param.optimalMax!;
    }
    final yPad = ((maxY - minY) * 0.15).clamp(0.5, double.infinity);
    minY -= yPad;
    maxY += yPad;
    final labelColor = colorScheme.onSurfaceVariant;
    final gridColor = colorScheme.outlineVariant;

    List<HorizontalLine> extraLines = [];
    if (param.optimalMin != null) {
      extraLines.add(
        HorizontalLine(
          y: param.optimalMin!,
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
              fontSize: 10,
            ),
            labelResolver: (line) => 'Min ${line.y}',
          ),
        ),
      );
    }
    if (param.optimalMax != null) {
      extraLines.add(
        HorizontalLine(
          y: param.optimalMax!,
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
              fontSize: 10,
            ),
            labelResolver: (line) => 'Max ${line.y}',
          ),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: records.length > 1 ? (records.length - 1).toDouble() : 1.0,
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
                    child: Text(
                      _formatAxisValue(value),
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
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
                    child: Text(
                      '${dt.month}/${dt.day}',
                      style: TextStyle(
                        color: labelColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 42,
                getTitlesWidget: (value, meta) => const SizedBox.shrink(),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
              if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
                return;
              }
              final spotIndex = response.lineBarSpots!.first.spotIndex;
              if (spotIndex != _lastTouchedSpotIndex) {
                _lastTouchedSpotIndex = spotIndex;
                HapticFeedback.selectionClick();
              }
            },
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) => colorScheme.inverseSurface,
              tooltipBorder: BorderSide(
                color: param.getColor(context).withValues(alpha: 0.3),
              ),
              tooltipBorderRadius: BorderRadius.circular(12),
              getTooltipItems: (spots) => spots.map((s) {
                final record = records[s.spotIndex];
                final dt = record.timestamp;
                final unit = param.unit.isEmpty ? '' : ' ${param.unit}';
                return LineTooltipItem(
                  '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n${s.y.toStringAsFixed(2)}$unit',
                  TextStyle(
                    color: param.getColor(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: param.getColor(context),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: records.length <= 15,
                getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                  radius: 3.5,
                  color: colorScheme.surface,
                  strokeWidth: 2,
                  strokeColor: param.getColor(context),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    param.getColor(context).withValues(alpha: 0.22),
                    param.getColor(context).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutQuad,
      ),
    );
  }

  Widget _buildRangeLegend(ParameterItem param, bool isDark, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (param.optimalMin != null) ...[
          _legendDash(Colors.green),
          const SizedBox(width: 4),
          Text(
            'Min ${param.optimalMin}${param.unit.isEmpty ? '' : ' ${param.unit}'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (param.optimalMax != null) ...[
          _legendDash(Colors.red),
          const SizedBox(width: 4),
          Text(
            'Max ${param.optimalMax}${param.unit.isEmpty ? '' : ' ${param.unit}'}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _legendDash(Color color) => Container(
    width: 20,
    height: 2,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _buildLoadingCard(bool isDark, Color color, ThemeData theme) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: _buildCard(
          isDark: isDark,
          color: color,
          theme: theme,
          child: const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );

  Widget _buildSinglePointCard(
    _DailyRecord record,
    ParameterItem param,
    bool isDark,
    ThemeData theme,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: _buildCard(
      isDark: isDark,
      color: param.getColor(context),
      theme: theme,
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${record.averageValue.toStringAsFixed(2)}${param.unit.isEmpty ? '' : ' ${param.unit}'}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: param.getColor(context),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Only 1 data point recorded',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add more measurements to see a trend line.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildEmptyCard(
    ParameterItem param,
    bool isDark,
    ThemeData theme,
  ) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: _buildCard(
      isDark: isDark,
      color: param.getColor(context),
      theme: theme,
      child: SizedBox(
        height: 220,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_rounded,
              size: 48,
              color: param.getColor(context).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'No data recorded yet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Record your first ${param.label} measurement\nto see the trend here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildErrorCard(String error, bool isDark, ThemeData theme) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Failed to load data:\n$error',
        style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _buildCard({
    required bool isDark,
    required Color color,
    required Widget child,
    required ThemeData theme,
  }) => Container(
    padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: theme.colorScheme.outlineVariant),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
    ),
    child: child,
  );

  String _formatAxisValue(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  double _xInterval(int count) {
    if (count <= 1) return 1.0;
    if (count <= 7) return 1.0;
    if (count <= 15) return 3.0;
    return 5.0;
  }
}
