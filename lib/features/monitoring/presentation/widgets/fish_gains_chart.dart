import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/presentation/growth_data_service.dart';

class FishGainsChart extends StatefulWidget {
  final List<GrowthMetrics> metrics;

  const FishGainsChart({
    super.key,
    required this.metrics,
  });

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
            "FISH GAINS",
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
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

    // Pre-calculate min/max for normalization
    double abwMin = double.infinity;
    double abwMax = -double.infinity;
    double adgMin = double.infinity;
    double adgMax = -double.infinity;
    double dfrMin = double.infinity;
    double dfrMax = -double.infinity;
    double fcrMin = double.infinity;
    double fcrMax = -double.infinity;

    for (var m in widget.metrics) {
      if (m.abw < abwMin) abwMin = m.abw;
      if (m.abw > abwMax) abwMax = m.abw;
      if (m.adg < adgMin) adgMin = m.adg;
      if (m.adg > adgMax) adgMax = m.adg;
      if (m.dfr < dfrMin) dfrMin = m.dfr;
      if (m.dfr > dfrMax) dfrMax = m.dfr;
      if (m.fcr < fcrMin) fcrMin = m.fcr;
      if (m.fcr > fcrMax) fcrMax = m.fcr;
    }

    if (abwMin == abwMax) { abwMin -= 1; abwMax += 1; }
    if (adgMin == adgMax) { adgMin -= 1; adgMax += 1; }
    if (dfrMin == dfrMax) { dfrMin -= 1; dfrMax += 1; }
    if (fcrMin == fcrMax) { fcrMin -= 1; fcrMax += 1; }

    final Map<String, List<FlSpot>> normalizedSpots = {
      'ABW': [],
      'ADG': [],
      'DFR': [],
      'FCR': [],
    };

    for (int i = 0; i < widget.metrics.length; i++) {
      final m = widget.metrics[i];
      final x = i.toDouble();

      normalizedSpots['ABW']!.add(FlSpot(x, ((m.abw - abwMin) / (abwMax - abwMin) * 100).clamp(0, 100)));
      normalizedSpots['ADG']!.add(FlSpot(x, ((m.adg - adgMin) / (adgMax - adgMin) * 100).clamp(0, 100)));
      normalizedSpots['DFR']!.add(FlSpot(x, ((m.dfr - dfrMin) / (dfrMax - dfrMin) * 100).clamp(0, 100)));
      normalizedSpots['FCR']!.add(FlSpot(x, ((m.fcr - fcrMin) / (fcrMax - fcrMin) * 100).clamp(0, 100)));
    }

    for (var param in _visibleParameters.keys) {
      if (_visibleParameters[param] != true) continue;

      lineBars.add(
        LineChartBarData(
          spots: normalizedSpots[param]!,
          isCurved: true,
          color: _colors[param]!,
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
            interval: _calculateInterval(widget.metrics.length),
            getTitlesWidget: (value, meta) {
              if (value.toInt() < 0 ||
                  value.toInt() >= widget.metrics.length) {
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
                
                double actualValue = 0.0;
                if (matchedParam == 'ABW') actualValue = m.abw;
                if (matchedParam == 'ADG') actualValue = m.adg;
                if (matchedParam == 'DFR') actualValue = m.dfr;
                if (matchedParam == 'FCR') actualValue = m.fcr;

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
