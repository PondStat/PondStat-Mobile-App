import 'package:flutter/material.dart';

class ScheduleListItem extends StatelessWidget {
  final String day;
  final bool morningSelected;
  final bool afternoonSelected;
  final VoidCallback onToggleMorning;
  final VoidCallback onToggleAfternoon;

  const ScheduleListItem({
    super.key,
    required this.day,
    required this.morningSelected,
    required this.afternoonSelected,
    required this.onToggleMorning,
    required this.onToggleAfternoon,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: onSurface,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ShiftButton(
                    label: "Morning",
                    icon: Icons.wb_sunny_rounded,
                    isSelected: morningSelected,
                    onTap: onToggleMorning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ShiftButton(
                    label: "Afternoon",
                    icon: Icons.wb_twilight_rounded,
                    isSelected: afternoonSelected,
                    onTap: onToggleAfternoon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShiftButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeColor = label == "Morning"
        ? Colors.amber.shade700
        : Colors.indigo.shade600;

    final activeBgColor = isDark
        ? activeColor.withValues(alpha: 0.15)
        : (label == "Morning" ? Colors.amber.shade50 : Colors.indigo.shade50);

    final defaultBgColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : Colors.grey.shade50;
    final defaultBorderColor = isDark ? Colors.white12 : Colors.grey.shade200;
    final defaultIconTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade500;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected ? activeBgColor : defaultBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? activeColor : defaultBorderColor,
          width: 1.5,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? activeColor : defaultIconTextColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? activeColor : defaultIconTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
