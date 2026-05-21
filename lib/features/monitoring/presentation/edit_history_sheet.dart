import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
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

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    Query<Map<String, dynamic>> query = ref.read(monitoringRepositoryProvider)
        .measurementHistoryCollection
        .where('pondId', isEqualTo: widget.pondId);

    if (selectedFilter != 'all') {
      query = query.where('action', isEqualTo: selectedFilter);
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
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

          Row(
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

          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All", "all", colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip("Added", "create", colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip("Edited", "update", colorScheme),
                const SizedBox(width: 8),
                _buildFilterChip("Deleted", "delete", colorScheme),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingPlaceholder(message: "Loading history...");
                }
                if (snapshot.hasError) {
                  return ErrorStateCard(
                    description: "Error: ${snapshot.error}",
                    onRetry: _refreshHistory,
                  );
                }

                var docs = snapshot.data?.docs.toList() ?? [];
                docs.sort((a, b) {
                  final tA = a.data()['editedAt'] as Timestamp?;
                  final tB = b.data()['editedAt'] as Timestamp?;
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return RefreshIndicator(
                  onRefresh: _refreshHistory,
                  color: colorScheme.primary,
                  backgroundColor: colorScheme.surface,
                  child: docs.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: EmptyStateCard(
                            image: const Icon(Icons.history_rounded),
                            title: "No history yet",
                            description:
                                "Changes made to the sampling metrics will appear here.",
                            scrollable: true,
                          ),
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: widget.scrollController,
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final data = docs[index].data();
                            final before = data['before'] ?? {};
                            final after = data['after'] ?? {};
                            String action = data['action'] ?? 'unknown';

                            if (action == 'unknown') {
                              if (data['before'] == null && data['after'] != null) {
                                action = 'create';
                              } else if (data['before'] != null &&
                                  data['after'] == null) {
                                action = 'delete';
                              } else {
                                action = 'update';
                              }
                            }

                            final ts = data['editedAt'] as Timestamp?;
                            final date = ts?.toDate();

                            Color actionColor;
                            IconData actionIcon;
                            if (action == 'delete') {
                              actionColor = Colors.red;
                              actionIcon = Icons.remove_circle_rounded;
                            } else if (action == 'create') {
                              actionColor = Colors.green;
                              actionIcon = Icons.add_circle_rounded;
                            } else {
                              actionColor = Colors.blue;
                              actionIcon = Icons.edit_rounded;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(20),
                                border: Border(
                                  left: BorderSide(color: actionColor, width: 6),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            physics: const BouncingScrollPhysics(),
                                            child: Text(
                                              data['parameter'] ?? 'Unknown',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                                color: onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: actionColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                actionIcon,
                                                size: 12,
                                                color: actionColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                action.toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.5,
                                                  color: actionColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline_rounded,
                                          size: 16,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "${data['editorName'] ?? 'Unknown'}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          date != null ? _formatRelativeTime(date) : '',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (action != 'create')
                                      Container(
                                        margin: const EdgeInsets.only(top: 12),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Was:",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${before['value'] ?? '-'}",
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    if (action != 'delete')
                                      Container(
                                        margin: const EdgeInsets.only(top: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              "Now:",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "${after['value'] ?? '-'}",
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
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
