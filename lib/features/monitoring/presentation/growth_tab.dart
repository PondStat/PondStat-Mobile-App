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
  final Color textDark = const Color(0xFF1E293B);
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
                  return _buildGrowthCard(metrics[index]);
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

  Widget _buildGrowthCard(GrowthMetrics m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(m.date),
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "ABW: ${m.abw}g",
                      style: TextStyle(
                        color: primaryIndigo,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
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
                              Icon(Icons.edit_rounded, size: 18, color: primaryIndigo),
                              const SizedBox(width: 12),
                              const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                "ADG",
                "${m.adg.toStringAsFixed(2)}g",
                Colors.green,
              ),
              _buildMiniMetric("FCR", m.fcr.toStringAsFixed(2), Colors.orange),
              _buildMiniMetric("DFR", m.dfr.toStringAsFixed(2), Colors.purple),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric("Total Weight", "${m.totalWeight}g", Colors.blueGrey),
              _buildMiniMetric("Sample Count", "${m.sampleCount.toInt()} pcs", Colors.blueGrey),
              const SizedBox(width: 40), // Spacer
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric("Feed Rate", "${m.feedingRate}%", Colors.brown),
              _buildMiniMetric("Feed Consumed", "${m.feedConsumed}kg", Colors.brown),
              _buildMiniMetric("Weight Gained", "${m.weightGained}kg", Colors.brown),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 8),
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
                Text("•", style: TextStyle(color: Colors.grey.shade300, fontSize: 11)),
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
      children: [
        Text(
          value,
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
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


