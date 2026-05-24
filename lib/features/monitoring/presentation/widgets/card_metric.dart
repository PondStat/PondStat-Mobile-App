import 'package:flutter/material.dart';

class CardMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;
  final Color? valueColor;

  const CardMetric({
    super.key,
    required this.label,
    required this.value,
    this.isHighlighted = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? colorScheme.onSurface,
            fontWeight: isHighlighted ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
