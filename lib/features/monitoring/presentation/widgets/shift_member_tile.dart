import 'package:flutter/material.dart';
import 'package:pondstat/core/utils/string_extensions.dart';

class ShiftMemberTile extends StatelessWidget {
  final String name;
  final bool isAssigned;
  final ValueChanged<bool?> onChanged;

  const ShiftMemberTile({
    super.key,
    required this.name,
    required this.isAssigned,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final primaryBlue = const Color(0xFF0A74DA);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isAssigned
            ? primaryBlue.withValues(alpha: 0.15)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAssigned
              ? primaryBlue.withValues(alpha: 0.3)
              : (isDark
                    ? Colors.white12
                    : Colors.grey.shade200),
        ),
      ),
      child: CheckboxListTile(
        value: isAssigned,
        onChanged: onChanged,
        activeColor: primaryBlue,
        checkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        checkboxShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: isDark
                  ? Colors.white12
                  : Colors.grey.shade200,
              child: Text(
                (name as String?).initials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white70
                      : Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isAssigned
                      ? FontWeight.w800
                      : FontWeight.w600,
                  color: onSurface,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
