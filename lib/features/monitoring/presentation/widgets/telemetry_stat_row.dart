import 'package:flutter/material.dart';

class TelemetryStatRow extends StatelessWidget {
  final List<double> values;
  final String unit;
  final Color themeColor;

  const TelemetryStatRow({
    super.key,
    required this.values,
    required this.unit,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final latest = values.last;
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    final unitSuffix = unit.isEmpty ? '' : ' $unit';

    return Row(
      children: [
        _buildStatChip(
          context: context,
          label: 'Latest',
          value: '${latest.toStringAsFixed(2)}$unitSuffix',
          color: themeColor,
          isDark: isDark,
          colorScheme: colorScheme,
          isHighlighted: true,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context: context,
          label: 'Avg',
          value: '${avg.toStringAsFixed(2)}$unitSuffix',
          color: themeColor,
          isDark: isDark,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context: context,
          label: 'Min',
          value: '${min.toStringAsFixed(2)}$unitSuffix',
          color: themeColor,
          isDark: isDark,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          context: context,
          label: 'Max',
          value: '${max.toStringAsFixed(2)}$unitSuffix',
          color: themeColor,
          isDark: isDark,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required ColorScheme colorScheme,
    bool isHighlighted = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isHighlighted
              ? color.withValues(alpha: 0.12)
              : colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: isHighlighted
              ? Border.all(color: color.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isHighlighted ? color : colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isHighlighted ? color : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
