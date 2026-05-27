import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/history_log_tile.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';

class EditHistorySheet extends ConsumerStatefulWidget {
  final String pondId;
  final ScrollController scrollController;

  const EditHistorySheet({
    super.key,
    required this.pondId,
    required this.scrollController,
  });

  @override
  ConsumerState<EditHistorySheet> createState() => _EditHistorySheetState();
}

class _EditHistorySheetState extends ConsumerState<EditHistorySheet> {
  String selectedFilter = 'all';

  Future<void> _refreshHistory() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    Query<Map<String, dynamic>> query = ref
        .read(monitoringRepositoryProvider)
        .measurementHistoryCollection
        .where('pondId', isEqualTo: widget.pondId);

    if (selectedFilter == 'create') {
      query = query.where('action', whereIn: const ['create', 'growth_create']);
    } else if (selectedFilter == 'update') {
      query = query.where('action', whereIn: const ['update', 'growth_update']);
    } else if (selectedFilter != 'all') {
      query = query.where('action', isEqualTo: selectedFilter);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 20),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
          final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
          final bool hasError = snapshot.hasError;

          if (snapshot.hasData) {
            docs = snapshot.data!.docs.toList();
            docs.sort((a, b) {
              final tA = a.data()['editedAt'] as Timestamp?;
              final tB = b.data()['editedAt'] as Timestamp?;
              if (tA == null || tB == null) return 0;
              return tB.compareTo(tA);
            });
          } else {
            docs = [];
          }

          return RefreshIndicator(
            onRefresh: _refreshHistory,
            color: colorScheme.primary,
            backgroundColor: colorScheme.surface,
            child: CustomScrollView(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // 1. Drag handle
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // 2. Title & close button Row
                SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "History",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: onSurface,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                // 3. Filter chips
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("All", "all", colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip("Added", "create", colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip("Edited", "update", colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip("Alerts", "alert", colorScheme),
                        const SizedBox(width: 8),
                        _buildFilterChip("Deleted", "delete", colorScheme),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                // 4. Content (Loading, Error, Empty, or List)
                if (isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: LoadingPlaceholder(message: "Loading history..."),
                    ),
                  )
                else if (hasError)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: ErrorStateCard(
                        description: "Error: ${snapshot.error}",
                        onRetry: _refreshHistory,
                      ),
                    ),
                  )
                else if (docs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: EmptyStateCard(
                          image: const Icon(Icons.history_rounded),
                          title: "No history yet",
                          description:
                              "Changes made to the sampling metrics will appear here.",
                          scrollable: false,
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final data = docs[index].data();
                        return HistoryLogTile(data: data);
                      },
                      childCount: docs.length,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = selectedFilter == value;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF0A74DA),
        backgroundColor: colorScheme.outlineVariant,
        showCheckmark: false,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() {
            selectedFilter = value;
          });
        },
      ),
    );
  }
}
