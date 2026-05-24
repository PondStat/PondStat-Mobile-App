import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/growth_metric_card.dart';
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
                      child: GrowthMetricCard(
                        current: current,
                        previous: previous,
                        canEdit: widget.canEdit,
                        onEdit: widget.onEdit,
                        onDelete: widget.onDelete,
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
}
