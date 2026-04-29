import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/presentation/trends_data_service.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class ChemicalParametersChartTwo extends StatefulWidget {
  final Map<String, List<NormalizedTrendPoint>> normalizedData;
  final String species;

  const ChemicalParametersChartTwo({
    super.key,
    required this.normalizedData,
    required this.species,
  });

  @override
  State<ChemicalParametersChartTwo> createState() =>
      _ChemicalParametersChartTwoState();
}

class _ChemicalParametersChartTwoState
    extends State<ChemicalParametersChartTwo> {
  final Map<String, bool> _visibleParameters = {
    'Magnesium': true,
    'Calcium': true,
    'Total Alkalinity': true,
  };

  @override
  Widget build(BuildContext context) {
    if (widget.normalizedData.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: Colors.white12) : null,
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
            "CHEMICAL PARAMETERS",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Minerals & Alkalinity",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey.shade800,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 220, child: LineChart(_buildChartData(isDark))),
          const SizedBox(height: 24),
          _buildLegend(isDark),
        ],
      ),
    );
  }

  LineChartData _buildChartData(bool isDark) {
    List<LineChartBarData> lineBars = [];

    final Set<DateTime> allTimestamps = {};
    for (var list in widget.normalizedData.values) {
      allTimestamps.addAll(list.map((p) => p.timestamp));
    }
    final sortedTimestamps = allTimestamps.toList()..sort();

    final Map<DateTime, int> timestampIndices = {};
    for (int i = 0; i < sortedTimestamps.length; i++) {
      timestampIndices[sortedTimestamps[i]] = i;
    }

    for (var entry in widget.normalizedData.entries) {
      final parameterName = entry.key;
      final points = entry.value;

      if (_visibleParameters[parameterName] != true) continue;

      final paramItem = MonitoringParameters.getParameterByLabel(
        parameterName,
        widget.species,
      );
      final color = paramItem?.color ?? Colors.grey;

      final spots = points.map((p) {
        final x = timestampIndices[p.timestamp]!.toDouble();
        return FlSpot(x, p.normalizedValue);
      }).toList();

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return LineChartData(
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
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateInterval(sortedTimestamps.length),
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 ||
                  value.toInt() >= sortedTimestamps.length) {
                return const SizedBox.shrink();
              }
              final date = sortedTimestamps[value.toInt()];
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
                  '${value.toInt()}%',
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
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => isDark
              ? Colors.black87
              : Colors.blueGrey.shade900.withValues(alpha: 0.9),
          tooltipBorderRadius: BorderRadius.circular(8),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              final timestamp = sortedTimestamps[barSpot.x.toInt()];

              String? matchedParam;
              int visibleIndex = 0;
              for (var key in widget.normalizedData.keys) {
                if (_visibleParameters[key] == true) {
                  if (visibleIndex == barSpot.barIndex) {
                    matchedParam = key;
                    break;
                  }
                  visibleIndex++;
                }
              }

              if (matchedParam != null) {
                final paramItem = MonitoringParameters.getParameterByLabel(
                  matchedParam,
                  widget.species,
                );
                final unit = paramItem?.unit ?? '';
                final color = paramItem?.color ?? Colors.white;

                final point = widget.normalizedData[matchedParam]!.firstWhere(
                  (p) => p.timestamp == timestamp,
                );

                return LineTooltipItem(
                  "$matchedParam\n${point.actualValue} $unit",
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
        final paramItem = MonitoringParameters.getParameterByLabel(
          param,
          widget.species,
        );
        final color = paramItem?.color ?? Colors.grey;
        final isVisible = _visibleParameters[param]!;

        return GestureDetector(
          onTap: () {
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
