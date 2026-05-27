import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimePickerCard extends StatelessWidget {
  final TimeOfDay selectedTime;
  final Color themeColor;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TimePickerCard({
    super.key,
    required this.selectedTime,
    required this.themeColor,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textDark = colorScheme.onSurface;
    final textMuted = colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selectedTime,
        );
        if (picked != null) {
          HapticFeedback.selectionClick();
          onTimeChanged(picked);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.access_time_filled_rounded,
                    color: textMuted,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  selectedTime.format(context),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: textDark,
                  ),
                ),
              ],
            ),
            Text(
              "Edit",
              style: TextStyle(color: themeColor, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
