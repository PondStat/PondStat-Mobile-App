import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';

class GrowthTab extends ConsumerStatefulWidget {
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
  ConsumerState<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends ConsumerState<GrowthTab> {
  final Color primaryIndigo = Colors.indigo;

  late Future<List<GrowthMetrics>> _growthMetricsFuture;

  @override
  void initState() {
    super.initState();
    _growthMetricsFuture = ref.read(growthRepositoryProvider).calculateGrowthMetrics(
      widget.pondId,
    );
  }

  @override
  void didUpdateWidget(covariant GrowthTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _growthMetricsFuture = ref.read(growthRepositoryProvider).calculateGrowthMetrics(
        widget.pondId,
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _growthMetricsFuture = ref.read(growthRepositoryProvider).calculateGrowthMetrics(
        widget.pondId,
      );
    });
    await _growthMetricsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return FutureBuilder<List<GrowthMetrics>>(
      future: _growthMetricsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder(message: "Loading growth metrics...");
        }

        if (snapshot.hasError) {
          return ErrorStateCard(
            description: "Error: ${snapshot.error}",
            onRetry: _refreshData,
          );
        }

        final metrics = snapshot.data ?? [];

        if (metrics.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refreshData,
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 32.0,
                    ),
                    child: Center(
                      child: EmptyStateCard(
                        image: const Icon(Icons.query_stats_rounded),
                        title: "No growth records",
                        description:
                            "Tap 'Record Sampling' to log a measurement.",
                        scrollable: false,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: colorScheme.primary,
          backgroundColor: colorScheme.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final current = metrics[index];
                    final previous = (index < metrics.length - 1)
                        ? metrics[index + 1]
                        : null;
                    return StaggeredListItem(
                      index: index,
                      child: _buildGrowthCard(
                        current,
                        previous,
                        colorScheme,
                        isDark,
                      ),
                    );
                  }, childCount: metrics.length),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 100), // Spacing for FAB
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrowthCard(
    GrowthMetrics m,
    GrowthMetrics? previous,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    double? deltaAbw;
    if (previous != null && m.abw != null && previous.abw != null) {
      deltaAbw = m.abw! - previous.abw!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Week ${m.weekNumber}",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(m.date),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
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
                            ? (isDark
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.green.shade50)
                            : (isDark
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : Colors.red.shade50),
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
                                ? (isDark
                                      ? Colors.green.shade400
                                      : Colors.green.shade700)
                                : (isDark
                                      ? Colors.red.shade400
                                      : Colors.red.shade700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${deltaAbw > 0 ? '+' : ''}${deltaAbw.toStringAsFixed(1)}g",
                            style: TextStyle(
                              color: deltaAbw > 0
                                  ? (isDark
                                        ? Colors.green.shade400
                                        : Colors.green.shade700)
                                  : (isDark
                                        ? Colors.red.shade400
                                        : Colors.red.shade700),
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
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: colorScheme.surfaceContainerHigh,
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
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: colorScheme.error,
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
              color: isDark
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.green.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniMetric(
                  "ABW",
                  m.abw != null ? "${m.abw}g" : "no input yet",
                  isDark ? Colors.green.shade300 : Colors.green.shade700,
                  colorScheme,
                ),
                _buildMiniMetric(
                  "ADG",
                  m.adg != null ? "${m.adg!.toStringAsFixed(2)}g" : "no input yet",
                  isDark ? Colors.green.shade300 : Colors.green.shade700,
                  colorScheme,
                ),
                _buildMiniMetric(
                  "FCR",
                  m.fcr != null ? m.fcr!.toStringAsFixed(2) : "no input yet",
                  isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                  colorScheme,
                ),
                _buildMiniMetric(
                  "DFR",
                  m.dfr != null ? m.dfr!.toStringAsFixed(2) : "no input yet",
                  isDark ? Colors.purple.shade300 : Colors.purple.shade700,
                  colorScheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // FOOTER: Editors
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      "By ${m.recorderName ?? 'Unknown'}",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (m.editorName != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        "•",
                        style: TextStyle(
                          color: colorScheme.outlineVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "Edited by ${m.editorName}",
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(
    String label,
    String value,
    Color color,
    ColorScheme colorScheme,
  ) {
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
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
