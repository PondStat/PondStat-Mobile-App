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
    final activeColor = label == "Morning"
        ? Colors.amber.shade700
        : Colors.indigo.shade600;
    final activeBgColor = label == "Morning"
        ? Colors.amber.shade50
        : Colors.indigo.shade50;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade200,
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : Colors.grey.shade400,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
