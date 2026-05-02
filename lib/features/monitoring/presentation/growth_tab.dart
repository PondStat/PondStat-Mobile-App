import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/presentation/growth_data_service.dart';

class GrowthTab extends StatefulWidget {
  final String pondId;
  final bool canEdit;
  final void Function(GrowthMetrics) onEdit;
  final void Function(GrowthMetrics) onDelete;

  const GrowthTab({
    super.key,
    required this.pondId,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<GrowthTab> {
  final Color primaryIndigo = Colors.indigo;
  Color get textDark => Theme.of(context).colorScheme.onSurface;
  final Color textMuted = const Color(0xFF64748B);

  late Future<List<GrowthMetrics>> _growthMetricsFuture;

  @override
  void initState() {
    super.initState();
    _growthMetricsFuture = GrowthDataService.calculateGrowthMetrics(
      widget.pondId,
    );
  }

  @override
  void didUpdateWidget(covariant GrowthTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _growthMetricsFuture = GrowthDataService.calculateGrowthMetrics(
        widget.pondId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GrowthMetrics>>(
      future: _growthMetricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final metrics = snapshot.data ?? [];

        if (metrics.isEmpty) {
          return _buildEmptyState();
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final current = metrics[index];
                  final previous = (index < metrics.length - 1)
                      ? metrics[index + 1]
                      : null;
                  return _buildGrowthCard(current, previous);
                }, childCount: metrics.length),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100), // Spacing for FAB
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrowthCard(GrowthMetrics m, GrowthMetrics? previous) {
    double? deltaAbw;
    if (previous != null) {
      deltaAbw = m.abw - previous.abw;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER: Date & Options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Week ${m.weekNumber}",
                    style: TextStyle(
                      color: textDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(m.date),
                    style: TextStyle(
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (deltaAbw != null && deltaAbw != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: deltaAbw > 0
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            deltaAbw > 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            size: 14,
                            color: deltaAbw > 0
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${deltaAbw > 0 ? '+' : ''}${deltaAbw.toStringAsFixed(1)}g",
                            style: TextStyle(
                              color: deltaAbw > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.canEdit) ...[
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_horiz_rounded,
                        color: Colors.grey.shade400,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') widget.onEdit(m);
                        if (value == 'delete') widget.onDelete(m);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: primaryIndigo,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Edit',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // GROUP 1: Growth Performance (Green)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniMetric("ABW", "${m.abw}g", Colors.green.shade700),
                _buildMiniMetric(
                  "ADG",
                  "${m.adg.toStringAsFixed(2)}g",
                  Colors.green.shade700,
                ),
                _buildMiniMetric(
                  "FCR",
                  m.fcr.toStringAsFixed(2),
                  Colors.orange.shade700,
                ),
                _buildMiniMetric(
                  "DFR",
                  m.dfr.toStringAsFixed(2),
                  Colors.purple.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // GROUP 2: Sampling Data (Blue)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMiniMetric(
                  "Total Weight",
                  "${m.totalWeight}g",
                  Colors.blue.shade700,
                ),
                _buildMiniMetric(
                  "Sample Count",
                  "${m.sampleCount.toInt()} pcs",
                  Colors.blue.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // GROUP 3: Feed Data (Orange)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniMetric(
                  "Feed Rate",
                  "${m.feedingRate}%",
                  Colors.brown.shade700,
                ),
                _buildMiniMetric(
                  "Consumed",
                  "${m.feedConsumed}kg",
                  Colors.brown.shade700,
                ),
                _buildMiniMetric(
                  "W. Gained",
                  "${m.weightGained}kg",
                  Colors.brown.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FOOTER: Editors
          Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: textMuted),
              const SizedBox(width: 4),
              Text(
                "By ${m.recorderName ?? 'Unknown'}",
                style: TextStyle(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (m.editorName != null) ...[
                const SizedBox(width: 8),
                Text(
                  "•",
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Icon(Icons.edit_rounded, size: 12, color: textMuted),
                const SizedBox(width: 4),
                Text(
                  "Edited by ${m.editorName}",
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No Growth Records Yet",
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Start recording weight and fish count weekly to see performance metrics here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
