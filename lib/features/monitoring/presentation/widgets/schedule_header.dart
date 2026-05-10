import 'package:flutter/material.dart';

class ScheduleHeader extends StatelessWidget {
  final String pondName;

  const ScheduleHeader({
    super.key,
    required this.pondName,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    const primaryBlue = Color(0xFF0A74DA);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryBlue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_note_rounded, color: primaryBlue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Schedule Manager",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: onSurface,
                ),
              ),
              Text(
                pondName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }
}
