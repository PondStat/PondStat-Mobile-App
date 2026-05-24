import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';

class GrowthMetricCard extends StatelessWidget {
  final GrowthMetrics current;
  final GrowthMetrics? previous;
  final bool canEdit;
  final void Function(GrowthMetrics) onEdit;
  final void Function(GrowthMetrics) onDelete;

  const GrowthMetricCard({
    super.key,
    required this.current,
    this.previous,
    this.canEdit = true,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    double? deltaAbw;
    if (previous != null && current.abw != null && previous!.abw != null) {
      deltaAbw = current.abw! - previous!.abw!;
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
                      "Week ${current.weekNumber}",
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(current.date),
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
                  if (canEdit) ...[
                    const SizedBox(width: 8),
                    Semantics(
                      label: "Growth sampling actions menu",
                      button: true,
                      child: PopupMenuButton<String>(
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
                          if (value == 'edit') onEdit(current);
                          if (value == 'delete') onDelete(current);
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
                  current.abw != null ? "${current.abw}g" : "n/a",
                  isDark ? Colors.green.shade300 : Colors.green.shade700,
                  colorScheme,
                ),
                _buildMiniMetric(
                  "ADG",
                  current.adg != null ? "${current.adg!.toStringAsFixed(2)}g" : "n/a",
                  isDark ? Colors.green.shade300 : Colors.green.shade700,
                  colorScheme,
                ),
                _buildMiniMetric(
                  "FCR",
                  current.fcr != null ? current.fcr!.toStringAsFixed(2) : "n/a",
                  isDark ? Colors.orange.shade300 : Colors.orange.shade700,
                  colorScheme,
                ),
                _buildMiniMetric(
                  "DFR",
                  current.dfr != null ? current.dfr!.toStringAsFixed(2) : "n/a",
                  isDark ? Colors.purple.shade300 : Colors.purple.shade700,
                  colorScheme,
                ),
              ],
            ),
          ),
          if (current.notes != null && current.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.tertiary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_rounded,
                    size: 16,
                    color: colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      current.notes!,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                      "By ${current.recorderName ?? 'Unknown'}",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (current.editorName != null) ...[
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
                          "Edited by ${current.editorName}",
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
