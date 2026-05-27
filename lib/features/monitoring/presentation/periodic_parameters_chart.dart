import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/telemetry_stat_row.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/core/services/weather_service.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';

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
  final GlobalKey? weatherOverlayKey;

  const PeriodicParametersChart({
    super.key,
    required this.pondId,
    required this.species,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.weatherOverlayKey,
  });

  @override
  ConsumerState<PeriodicParametersChart> createState() =>
      _PeriodicParametersChartState();
}

class _PeriodicParametersChartState extends ConsumerState<PeriodicParametersChart>
    with SingleTickerProviderStateMixin {
  late final List<ParameterItem> _baseParams;
  int _selectedIndex = 0;
  String _selectedWeatherOverlay = 'None'; // 'None', 'Rainfall', 'Air Temp', 'UV Index'

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
            const SizedBox(height: 12),
            _buildWeatherOverlaySelector(theme, isDark),
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

  Widget _buildWeatherOverlaySelector(ThemeData theme, bool isDark) {
    final colorScheme = theme.colorScheme;
    final options = ['None', 'Rainfall', 'Air Temp', 'UV Index'];
    final selectorWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'Weather Overlay:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: options.map((opt) {
                  final active = _selectedWeatherOverlay == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: ChoiceChip(
                      label: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: active ? Colors.white : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      selected: active,
                      onSelected: (val) {
                        if (val) {
                          setState(() {
                            _selectedWeatherOverlay = opt;
                          });
                        }
                      },
                      selectedColor: const Color(0xFF0D9488),
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: active ? Colors.transparent : colorScheme.outlineVariant,
                        ),
                      ),
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.weatherOverlayKey != null) {
      return CustomShowcase(
        showcaseKey: widget.weatherOverlayKey!,
        scope: 'pond_monitoring',
        title: 'Weather Overlay Selector',
        description: 'Correlate daily parameter fluctuations (like Temperature and DO) with weather overlays such as Rainfall, Air Temperature, and UV index.',
        child: selectorWidget,
      );
    }
    return selectorWidget;
  }

  DailyWeatherData? _getWeatherForDate(DateTime timestamp, List<DailyWeatherData> weatherList) {
    for (var w in weatherList) {
      if (w.date.year == timestamp.year &&
          w.date.month == timestamp.month &&
          w.date.day == timestamp.day) {
        return w;
      }
    }
    return null;
  }

  Widget _buildChartArea(
    ThemeData theme,
    bool isDark,
    List<ParameterItem> params,
  ) {
    if (params.isEmpty) return const SizedBox.shrink();
    final param = params[_selectedIndex];

    return StreamBuilder<Pond>(
      stream: ref.read(pondRepositoryProvider).getPondStream(widget.pondId),
      builder: (context, pondSnap) {
        final pond = pondSnap.data;
        final lat = pond?.latitude ?? WeatherService.defaultLat;
        final lon = pond?.longitude ?? WeatherService.defaultLon;

        return FutureBuilder<List<DailyWeatherData>>(
          future: ref.read(weatherServiceProvider).fetchHistory(lat, lon, widget.startDate, widget.endDate),
          builder: (context, weatherSnap) {
            final weatherList = weatherSnap.data ?? [];

            return StreamBuilder<List<_DailyRecord>>(
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
                      TelemetryStatRow(
                        values: records.map((r) => r.averageValue).toList(),
                        unit: param.unit,
                        themeColor: param.getColor(context),
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        isDark: isDark,
                        color: param.getColor(context),
                        theme: theme,
                        child: _buildLineChart(records, param, weatherList, isDark, theme),
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
          },
        );
      },
    );
  }

  Widget _buildLineChart(
    List<_DailyRecord> records,
    ParameterItem param,
    List<DailyWeatherData> weatherList,
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

    final hasWeatherOverlay = _selectedWeatherOverlay != 'None' && weatherList.isNotEmpty;
    double minWeather = 0.0;
    double maxWeather = 1.0;
    List<FlSpot> weatherSpots = [];
    Color weatherColor = Colors.grey;

    if (hasWeatherOverlay) {
      if (_selectedWeatherOverlay == 'Rainfall') {
        weatherColor = const Color(0xFF3B82F6);
        final valuesList = weatherList.map((w) => w.rainfall ?? 0.0).toList();
        minWeather = 0.0;
        maxWeather = valuesList.isNotEmpty ? valuesList.reduce((a, b) => a > b ? a : b) : 10.0;
        if (maxWeather < 10.0) maxWeather = 10.0;
      } else if (_selectedWeatherOverlay == 'Air Temp') {
        weatherColor = const Color(0xFFEF4444);
        final valuesList = weatherList.map((w) => w.temperature ?? 0.0).toList();
        if (valuesList.isNotEmpty) {
          minWeather = valuesList.reduce((a, b) => a < b ? a : b) - 2.0;
          maxWeather = valuesList.reduce((a, b) => a > b ? a : b) + 2.0;
        } else {
          minWeather = 20.0;
          maxWeather = 40.0;
        }
      } else if (_selectedWeatherOverlay == 'UV Index') {
        weatherColor = const Color(0xFF8B5CF6);
        final valuesList = weatherList.map((w) => w.uvIndex ?? 0.0).toList();
        minWeather = 0.0;
        maxWeather = valuesList.isNotEmpty ? valuesList.reduce((a, b) => a > b ? a : b) : 10.0;
        if (maxWeather < 5.0) maxWeather = 5.0;
      }

      for (int i = 0; i < records.length; i++) {
        final rec = records[i];
        final wData = _getWeatherForDate(rec.timestamp, weatherList);
        double wVal = 0.0;
        if (_selectedWeatherOverlay == 'Rainfall') {
          wVal = wData?.rainfall ?? 0.0;
        } else if (_selectedWeatherOverlay == 'Air Temp') {
          wVal = wData?.temperature ?? minWeather;
        } else if (_selectedWeatherOverlay == 'UV Index') {
          wVal = wData?.uvIndex ?? 0.0;
        }

        final double normalizedY;
        if (maxWeather == minWeather) {
          normalizedY = minY + (maxY - minY) / 2.0;
        } else {
          normalizedY = minY + (wVal - minWeather) / (maxWeather - minWeather) * (maxY - minY);
        }
        weatherSpots.add(FlSpot(i.toDouble(), normalizedY));
      }
    }

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
                showTitles: hasWeatherOverlay,
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (!hasWeatherOverlay) return const SizedBox.shrink();
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  final weatherVal = minWeather + (value - minY) / (maxY - minY) * (maxWeather - minWeather);
                  final unit = _selectedWeatherOverlay == 'Rainfall'
                      ? 'mm'
                      : _selectedWeatherOverlay == 'Air Temp'
                          ? '°C'
                          : '';
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      '${weatherVal.toStringAsFixed(1)}$unit',
                      style: TextStyle(
                        color: weatherColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  );
                },
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
                if (s.barIndex != 0) return null;

                final record = records[s.spotIndex];
                final dt = record.timestamp;
                final unit = param.unit.isEmpty ? '' : ' ${param.unit}';

                String tooltipText = '${dt.month}/${dt.day}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}\n';
                tooltipText += '${param.label}: ${s.y.toStringAsFixed(2)}$unit';

                if (hasWeatherOverlay) {
                  final wData = _getWeatherForDate(dt, weatherList);
                  if (_selectedWeatherOverlay == 'Rainfall') {
                    tooltipText += '\nRain: ${wData?.rainfall?.toStringAsFixed(1) ?? "0.0"} mm';
                  } else if (_selectedWeatherOverlay == 'Air Temp') {
                    tooltipText += '\nAir Temp: ${wData?.temperature?.toStringAsFixed(1) ?? "N/A"} °C';
                  } else if (_selectedWeatherOverlay == 'UV Index') {
                    tooltipText += '\nUV: ${wData?.uvIndex?.toStringAsFixed(1) ?? "N/A"}';
                  }
                }

                return LineTooltipItem(
                  tooltipText,
                  TextStyle(
                    color: param.getColor(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                );
              }).whereType<LineTooltipItem>().toList(),
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
            if (hasWeatherOverlay)
              LineChartBarData(
                spots: weatherSpots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: weatherColor,
                barWidth: 1.5,
                dashArray: [6, 4],
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(show: false),
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
