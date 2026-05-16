import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CultureProgressCard extends StatelessWidget {
  final DateTime createdAt;
  final int targetCulturePeriodDays;

  const CultureProgressCard({
    super.key,
    required this.createdAt,
    required this.targetCulturePeriodDays,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryBlue = theme.colorScheme.primary;
    final errorColor = theme.colorScheme.error;

    final now = DateTime.now();
    final startDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);

    // Calculate Day of Culture (DOC)
    int doc =
        today.difference(startDay).inDays + 1; // Day 1 starts on creation date
    if (doc < 0) doc = 0;

    final isOverdue =
        doc > targetCulturePeriodDays && targetCulturePeriodDays > 0;

    final progress = targetCulturePeriodDays > 0
        ? (doc / targetCulturePeriodDays).clamp(0.0, 1.0)
        : 0.0;

    final progressColor = isOverdue ? errorColor : primaryBlue;
    final docChipColor = isOverdue ? errorColor : primaryBlue;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 24,
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
                Text(
                  "Culture Progress",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: docChipColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "DOC $doc",
                    style: TextStyle(
                      color: docChipColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: progressColor,
                    minHeight: 10,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Start: ${DateFormat('MMM d').format(createdAt)}",
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isOverdue
                      ? "Overdue by ${doc - targetCulturePeriodDays} Days"
                      : "Target: $targetCulturePeriodDays Days",
                  style: TextStyle(
                    color: isOverdue
                        ? errorColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
