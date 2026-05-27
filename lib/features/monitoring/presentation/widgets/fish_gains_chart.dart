import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';

class FishGainsChart extends StatefulWidget {
  final List<GrowthMetrics> metrics;

  const FishGainsChart({super.key, required this.metrics});

  @override
  State<FishGainsChart> createState() => _FishGainsChartState();
}

class _FishGainsChartState extends State<FishGainsChart> {
  final Map<String, bool> _visibleParameters = {
    'ABW': true,
    'ADG': true,
    'DFR': true,
    'FCR': true,
  };
  int? _lastTouchedSpotIndex;

  final Map<String, Color> _colors = {
    'ABW': Colors.blue,
    'ADG': Colors.green,
    'DFR': Colors.orange,
    'FCR': Colors.purple,
  };

  final Map<String, String> _units = {
    'ABW': 'g',
    'ADG': 'g',
    'DFR': '%',
    'FCR': '',
  };

  @override
  Widget build(BuildContext context) {
    if (widget.metrics.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.metrics.length == 1) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(color: Colors.white12)
              : Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "FISH GAINS",
              style: TextStyle(
                color: Colors.blueGrey,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.metrics.first.abw != null
                        ? '${widget.metrics.first.abw!.toStringAsFixed(1)} g'
                        : 'NA',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: _colors['ABW'],
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
                    'Add more measurements to see growth trends.',
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
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: isDark
            ? Border.all(color: Colors.white12)
            : Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "FISH GAINS",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: LineChart(
              _buildChartData(isDark),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuad,
            ),
          ),
          const SizedBox(height: 24),
          _buildLegend(isDark),
        ],
      ),
    );
  }

  LineChartData _buildChartData(bool isDark) {
    List<LineChartBarData> lineBars = [];

    double minY = double.infinity;
    double maxY = -double.infinity;

    for (var m in widget.metrics) {
      if (_visibleParameters['ABW'] == true && m.abw != null) {
        if (m.abw! < minY) minY = m.abw!;
        if (m.abw! > maxY) maxY = m.abw!;
      }
      if (_visibleParameters['ADG'] == true && m.adg != null) {
        if (m.adg! < minY) minY = m.adg!;
        if (m.adg! > maxY) maxY = m.adg!;
      }
      if (_visibleParameters['DFR'] == true && m.dfr != null) {
        if (m.dfr! < minY) minY = m.dfr!;
        if (m.dfr! > maxY) maxY = m.dfr!;
      }
      if (_visibleParameters['FCR'] == true && m.fcr != null) {
        if (m.fcr! < minY) minY = m.fcr!;
        if (m.fcr! > maxY) maxY = m.fcr!;
      }
    }

    if (minY == double.infinity || maxY == -double.infinity) {
      minY = 0.0;
      maxY = 10.0;
    } else if (minY == maxY) {
      minY = (minY - 1.0).clamp(0.0, double.infinity);
      maxY = maxY + 1.0;
    } else {
      final padding = (maxY - minY) * 0.15;
      minY = (minY - padding).clamp(0.0, double.infinity);
      maxY = maxY + padding;
    }

    for (var param in _visibleParameters.keys) {
      if (_visibleParameters[param] != true) continue;

      final spots = <FlSpot>[];
      for (int i = 0; i < widget.metrics.length; i++) {
        final m = widget.metrics[i];
        final x = i.toDouble();
        double? val;
        if (param == 'ABW') val = m.abw;
        if (param == 'ADG') val = m.adg;
        if (param == 'DFR') val = m.dfr;
        if (param == 'FCR') val = m.fcr;

        if (val != null) {
          spots.add(FlSpot(x, val));
        }
      }

      if (spots.isNotEmpty) {
        lineBars.add(
          LineChartBarData(
            spots: spots,
            isCurved: spots.length > 1,
            color: _colors[param]!,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: spots.length == 1),
            belowBarData: BarAreaData(show: false),
          ),
        );
      }
    }

    return LineChartData(
      minY: minY,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => const SizedBox.shrink(),
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateInterval(widget.metrics.length),
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 || value.toInt() >= widget.metrics.length) {
                return const SizedBox.shrink();
              }
              final date = widget.metrics[value.toInt()].date;
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return SideTitleWidget(
                meta: meta,
                child: Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey.shade400,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: lineBars,
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
          getTooltipColor: (touchedSpot) =>
              Theme.of(context).colorScheme.inverseSurface,
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              final index = barSpot.x.toInt();
              final m = widget.metrics[index];

              String? matchedParam;
              int visibleIndex = 0;
              for (var key in _visibleParameters.keys) {
                if (_visibleParameters[key] == true) {
                  if (visibleIndex == barSpot.barIndex) {
                    matchedParam = key;
                    break;
                  }
                  visibleIndex++;
                }
              }

              if (matchedParam != null) {
                final color = _colors[matchedParam] ?? Colors.white;
                final unit = _units[matchedParam] ?? '';

                double? actualValue;
                if (matchedParam == 'ABW') actualValue = m.abw;
                if (matchedParam == 'ADG') actualValue = m.adg;
                if (matchedParam == 'DFR') actualValue = m.dfr;
                if (matchedParam == 'FCR') actualValue = m.fcr;

                if (actualValue == null) return null;

                return LineTooltipItem(
                  "$matchedParam\n${actualValue.toStringAsFixed(2)}$unit",
                  TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  double _calculateInterval(int length) {
    if (length <= 5) return 1;
    if (length <= 14) return 2;
    return (length / 5).floorToDouble();
  }

  Widget _buildLegend(bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _visibleParameters.keys.map((param) {
        final color = _colors[param]!;
        final isVisible = _visibleParameters[param]!;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _visibleParameters[param] = !isVisible;
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isVisible
                      ? color
                      : (isDark ? Colors.white24 : Colors.grey.shade300),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                param,
                style: TextStyle(
                  color: isVisible
                      ? (isDark ? Colors.white70 : Colors.grey.shade800)
                      : (isDark ? Colors.white38 : Colors.grey.shade500),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  decoration: isVisible ? null : TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
