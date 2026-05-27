import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

class CorrelationResult {
  final double coefficient;
  final List<double> xValues;
  final List<double> yValues;
  final List<String> dates;
  final double slope;
  final double intercept;

  CorrelationResult({
    required this.coefficient,
    required this.xValues,
    required this.yValues,
    required this.dates,
    required this.slope,
    required this.intercept,
  });
}

class CorrelationTab extends ConsumerStatefulWidget {
  final String pondId;
  final String species;
  final DateTime startDate;
  final DateTime endDate;

  const CorrelationTab({
    super.key,
    required this.pondId,
    required this.species,
    required this.startDate,
    required this.endDate,
  });

  @override
  ConsumerState<CorrelationTab> createState() => _CorrelationTabState();
}

class _CorrelationTabState extends ConsumerState<CorrelationTab> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _measurementsStream;

  String? _selectedParamX;
  String? _selectedParamY;

  @override
  void initState() {
    super.initState();
    _initDataStream();
  }

  @override
  void didUpdateWidget(covariant CorrelationTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId ||
        oldWidget.startDate != widget.startDate ||
        oldWidget.endDate != widget.endDate) {
      _initDataStream();
    }
  }

  void _initDataStream() {
    _measurementsStream = ref
        .read(monitoringRepositoryProvider)
        .getMeasurementsByDateRange(
          widget.pondId,
          widget.startDate,
          widget.endDate,
        )
        .snapshots();
  }

  CorrelationResult? _calculateCorrelation(List<double> x, List<double> y, List<String> dates) {
    if (x.length < 3 || x.length != y.length) return null;
    final n = x.length;
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;

    double sumProduct = 0;
    double sumSquareX = 0;
    double sumSquareY = 0;

    for (int i = 0; i < n; i++) {
      final diffX = x[i] - meanX;
      final diffY = y[i] - meanY;
      sumProduct += diffX * diffY;
      sumSquareX += diffX * diffX;
      sumSquareY += diffY * diffY;
    }

    if (sumSquareX == 0 || sumSquareY == 0) return null;

    final coefficient = sumProduct / math.sqrt(sumSquareX * sumSquareY);
    final slope = sumProduct / sumSquareX;
    final intercept = meanY - slope * meanX;

    return CorrelationResult(
      coefficient: coefficient,
      xValues: x,
      yValues: y,
      dates: dates,
      slope: slope,
      intercept: intercept,
    );
  }

  String _getParamAbbreviation(String label) {
    switch (label) {
      case 'pH Level':
        return 'pH';
      case 'Dissolved Oxygen':
        return 'DO';
      case 'Temperature':
        return 'Temp';
      case 'Salinity':
        return 'Sal';
      case 'Transparency':
        return 'Trans';
      case 'Phytoplankton':
        return 'Phyto';
      default:
        if (label.length <= 5) return label;
        return label.substring(0, 4);
    }
  }

  Color _getCellColor(double r, bool isDark) {
    if (r > 0) {
      return Colors.teal.withValues(alpha: r.clamp(0.0, 1.0) * 0.7 + 0.15);
    } else {
      return Colors.deepOrange.withValues(alpha: r.abs().clamp(0.0, 1.0) * 0.7 + 0.15);
    }
  }

  String _getBiologicalInterpretation(String paramA, String paramB, double r) {
    final pair = {paramA, paramB};

    if (pair.contains('pH Level') && pair.contains('Dissolved Oxygen')) {
      if (r > 0.3) {
        return "Strong positive correlation is typical in ponds with active algae blooms. During the day, photosynthesis consumes carbon dioxide (which raises pH) and produces dissolved oxygen (raising DO). This diurnal rise couples both parameters.";
      } else if (r < -0.3) {
        return "A negative correlation is unusual and may indicate high bacterial respiration, dying algae blooms (which consume oxygen while decay produces organic acids that lower pH), or a critical chemical imbalance.";
      }
    }

    if (pair.contains('Temperature') && pair.contains('Dissolved Oxygen')) {
      if (r < -0.3) {
        return "This is a fundamental physical relationship: warm water holds less dissolved gases. As water temperature increases, the maximum saturation limit of Dissolved Oxygen drops, meaning DO will naturally decrease as water warms.";
      }
    }

    if (pair.contains('Transparency') && pair.contains('Phytoplankton')) {
      if (r < -0.3) {
        return "As phytoplankton concentrations increase (algae blooms), the water becomes less transparent. Thus, high biological counts correspond directly to lower transparency measurements.";
      }
    }

    if (pair.contains('Ammonia') && pair.contains('pH Level')) {
      if (r > 0.3) {
        return "High pH increases the proportion of toxic un-ionized ammonia (NH3) relative to ammonium (NH4+). Monitor this closely, as high pH makes any ammonia present much more lethal to the pond culture.";
      }
    }

    // Generic fallbacks
    if (r > 0.7) {
      return "Strong positive relationship. When one parameter rises, the other rises consistently. This suggests they are either directly influencing each other or responding to the same underlying environmental factor.";
    } else if (r >= 0.3) {
      return "Moderate positive relationship. There is a general trend where higher values of one correspond to higher values of the other, though other factors also influence their values.";
    } else if (r < -0.7) {
      return "Strong negative relationship. When one parameter rises, the other falls consistently. This indicates an inverse relationship between the two parameters.";
    } else if (r <= -0.3) {
      return "Moderate negative relationship. There is a general trend where higher values of one correspond to lower values of the other.";
    } else {
      return "Weak or negligible relationship. The values do not show any significant co-movement. They can be monitored independently.";
    }
  }

  String _getCorrelationStrengthText(double r) {
    final absR = r.abs();
    final direction = r >= 0 ? "Positive" : "Negative";
    if (absR > 0.7) return "Strong $direction";
    if (absR >= 0.3) return "Moderate $direction";
    return "Weak/No Correlation";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _measurementsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error loading data: ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: EmptyStateCard(
              image: const Icon(Icons.analytics_outlined),
              title: 'No Data Found',
              description: 'No measurements recorded for the selected date range.',
            ),
          );
        }

        // 1. Group measurements by dateKey
        final Map<String, Map<String, double>> dataByDate = {};
        for (var doc in docs) {
          final data = doc.data();
          final dateKey = data['dateKey'] as String? ?? '';
          final param = data['parameter'] as String? ?? '';
          final value = (data['value'] as num?)?.toDouble();
          if (dateKey.isNotEmpty && param.isNotEmpty && value != null) {
            dataByDate.putIfAbsent(dateKey, () => {})[param] = value;
          }
        }

        // 2. Identify active parameters
        final Set<String> activeParameters = {};
        for (var params in dataByDate.values) {
          activeParameters.addAll(params.keys);
        }
        final List<String> sortedParams = activeParameters.toList()..sort();

        if (sortedParams.length < 2) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: EmptyStateCard(
              image: const Icon(Icons.compare_arrows_rounded),
              title: 'Insufficient Parameters',
              description: 'You need at least 2 distinct parameters recorded during this period to analyze correlations.',
            ),
          );
        }

        // 3. Precalculate correlation matrix
        final Map<String, Map<String, CorrelationResult>> matrix = {};
        for (int i = 0; i < sortedParams.length; i++) {
          final paramA = sortedParams[i];
          matrix[paramA] = {};
          for (int j = 0; j < sortedParams.length; j++) {
            final paramB = sortedParams[j];
            if (i == j) continue;

            final List<double> xVals = [];
            final List<double> yVals = [];
            final List<String> dates = [];

            for (var entry in dataByDate.entries) {
              if (entry.value.containsKey(paramA) && entry.value.containsKey(paramB)) {
                xVals.add(entry.value[paramA]!);
                yVals.add(entry.value[paramB]!);
                dates.add(entry.key);
              }
            }

            final result = _calculateCorrelation(xVals, yVals, dates);
            if (result != null) {
              matrix[paramA]![paramB] = result;
            }
          }
        }

        // Verify if we have any valid correlations computed
        bool hasAnyCorrelations = false;
        for (var map in matrix.values) {
          if (map.isNotEmpty) {
            hasAnyCorrelations = true;
            break;
          }
        }

        if (!hasAnyCorrelations) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: EmptyStateCard(
              image: const Icon(Icons.bubble_chart_outlined),
              title: 'No Overlapping Data',
              description: 'Record measurements for different parameters on the same days to generate correlation analysis (minimum 3 days of overlapping data needed).',
            ),
          );
        }

        // Default selection if not set or invalid
        if (_selectedParamX == null || _selectedParamY == null || 
            !sortedParams.contains(_selectedParamX) || 
            !sortedParams.contains(_selectedParamY) || 
            _selectedParamX == _selectedParamY) {
          // Find the first pair that has a valid correlation
          String? foundX;
          String? foundY;
          for (var paramA in sortedParams) {
            if (matrix[paramA]?.isNotEmpty == true) {
              foundX = paramA;
              foundY = matrix[paramA]!.keys.first;
              break;
            }
          }
          _selectedParamX = foundX;
          _selectedParamY = foundY;
        }

        CorrelationResult? selectedResult;
        if (_selectedParamX != null && _selectedParamY != null) {
          selectedResult = matrix[_selectedParamX!]?[_selectedParamY!];
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            // Correlation Matrix Grid Card
            _buildMatrixCard(sortedParams, matrix, theme, isDark),
            const SizedBox(height: 20),

            // Scatter Plot Card
            if (selectedResult != null) ...[
              _buildScatterPlotCard(
                _selectedParamX!,
                _selectedParamY!,
                selectedResult,
                theme,
                isDark,
              ),
              const SizedBox(height: 20),

              // Interpretation Card
              _buildInterpretationCard(
                _selectedParamX!,
                _selectedParamY!,
                selectedResult.coefficient,
                theme,
                isDark,
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMatrixCard(
    List<String> params,
    Map<String, Map<String, CorrelationResult>> matrix,
    ThemeData theme,
    bool isDark,
  ) {
    final double cellSize = 48.0;
    final double headerSize = 56.0;

    return Container(
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
          Text(
            "CORRELATION MATRIX",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tap any cell to inspect scatter plot and cause-and-effect relationship.",
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y-axis Labels
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: headerSize, width: headerSize),
                    ...params.map((param) {
                      return SizedBox(
                        height: cellSize,
                        width: headerSize,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _getParamAbbreviation(param),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: (_selectedParamX == param || _selectedParamY == param)
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                // Matrix Cells
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // X-axis Labels (Header)
                    Row(
                      children: params.map((param) {
                        return SizedBox(
                          width: cellSize,
                          height: headerSize,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Text(
                                _getParamAbbreviation(param),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: (_selectedParamX == param || _selectedParamY == param)
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // Rows of Cells
                    ...params.map((paramRow) {
                      return Row(
                        children: params.map((paramCol) {
                          if (paramRow == paramCol) {
                            // Diagonal cell (Self correlation is always 1.0)
                            return Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  "1.0",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white30 : Colors.black26,
                                  ),
                                ),
                              ),
                            );
                          }

                          final result = matrix[paramRow]?[paramCol];
                          if (result == null) {
                            // Insufficient data cell
                            return Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  "N/A",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            );
                          }

                          final isSelected = (_selectedParamX == paramRow && _selectedParamY == paramCol) ||
                              (_selectedParamX == paramCol && _selectedParamY == paramRow);

                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedParamX = paramRow;
                                _selectedParamY = paramCol;
                              });
                            },
                            child: Container(
                              width: cellSize,
                              height: cellSize,
                              margin: const EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: _getCellColor(result.coefficient, isDark),
                                borderRadius: BorderRadius.circular(6),
                                border: isSelected
                                    ? Border.all(color: theme.colorScheme.primary, width: 2)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  result.coefficient.toStringAsFixed(2),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem("Positive (+)", Colors.teal, theme),
              const SizedBox(width: 24),
              _buildLegendItem("Negative (-)", Colors.deepOrange, theme),
              const SizedBox(width: 24),
              _buildLegendItem("Insufficient Data", Colors.grey, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildScatterPlotCard(
    String paramX,
    String paramY,
    CorrelationResult result,
    ThemeData theme,
    bool isDark,
  ) {
    final xValues = result.xValues;
    final yValues = result.yValues;

    final minXVal = xValues.reduce((a, b) => a < b ? a : b);
    final maxXVal = xValues.reduce((a, b) => a > b ? a : b);
    final minYVal = yValues.reduce((a, b) => a < b ? a : b);
    final maxYVal = yValues.reduce((a, b) => a > b ? a : b);

    final rangeX = maxXVal - minXVal;
    final rangeY = maxYVal - minYVal;

    final padX = rangeX == 0 ? 1.0 : rangeX * 0.15;
    final padY = rangeY == 0 ? 1.0 : rangeY * 0.15;

    final minX = minXVal - padX;
    final maxX = maxXVal + padX;
    final minY = minYVal - padY;
    final maxY = maxYVal + padY;

    // Generate spots for scatter points
    final List<FlSpot> scatterSpots = [];
    for (int i = 0; i < xValues.length; i++) {
      scatterSpots.add(FlSpot(xValues[i], yValues[i]));
    }

    // Generate spots for the regression line
    final List<FlSpot> lineSpots = [
      FlSpot(minX, minX * result.slope + result.intercept),
      FlSpot(maxX, maxX * result.slope + result.intercept),
    ];

    // Determine parameter units
    final unitX = MonitoringParameters.getParameterByLabel(paramX, widget.species)?.unit ?? '';
    final unitY = MonitoringParameters.getParameterByLabel(paramY, widget.species)?.unit ?? '';

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "SCATTER PLOT",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "${xValues.length} paired points",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "$paramY vs. $paramX",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      "$paramX (${unitX.isEmpty ? 'units' : unitX})",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      getTitlesWidget: (value, meta) {
                        if (value == minX || value == maxX) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      "$paramY (${unitY.isEmpty ? 'units' : unitY})",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    axisNameSize: 20,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == minY || value == maxY) return const SizedBox.shrink();
                        return SideTitleWidget(
                          meta: meta,
                          child: Text(
                            value.toStringAsFixed(1),
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Regression line (underneath points)
                  LineChartBarData(
                    spots: lineSpots,
                    show: true,
                    barWidth: 2,
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    dashArray: const [6, 4],
                    dotData: const FlDotData(show: false),
                  ),
                  // Scatter Points
                  LineChartBarData(
                    spots: scatterSpots,
                    show: true,
                    barWidth: 0,
                    color: Colors.transparent,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: theme.colorScheme.primary,
                          strokeWidth: 1.5,
                          strokeColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        );
                      },
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (touchedSpot) => theme.colorScheme.inverseSurface,
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      return touchedSpots.map((barSpot) {
                        if (barSpot.barIndex == 0) return null; // Ignore regression line touches
                        final dateStr = result.dates[barSpot.spotIndex];
                        return LineTooltipItem(
                          "Date: $dateStr\nX: ${barSpot.x.toStringAsFixed(2)} $unitX\nY: ${barSpot.y.toStringAsFixed(2)} $unitY",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Formula Legend
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 2,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "Line of Best Fit: y = ${result.slope.toStringAsFixed(2)}x + ${result.intercept.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterpretationCard(
    String paramA,
    String paramB,
    double r,
    ThemeData theme,
    bool isDark,
  ) {
    final strength = _getCorrelationStrengthText(r);
    final explanation = _getBiologicalInterpretation(paramA, paramB, r);
    final strengthColor = r.abs() >= 0.7 
        ? (r > 0 ? Colors.teal : Colors.deepOrange)
        : (r.abs() >= 0.3 ? theme.colorScheme.primary : Colors.grey);

    return Container(
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
          Text(
            "CAUSE-AND-EFFECT INTERPRETATION",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: strengthColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  r >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: strengthColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strength,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: strengthColor,
                      ),
                    ),
                    Text(
                      "Correlation coefficient r = ${r.toStringAsFixed(3)}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Text(
            explanation,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
