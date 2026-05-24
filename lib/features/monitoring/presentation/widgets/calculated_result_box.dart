import 'package:flutter/material.dart';

class CalculatedResultBox extends StatelessWidget {
  final String title;
  final double? value;
  final String unit;
  final Color color;

  const CalculatedResultBox({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            value != null ? "${value!.toStringAsFixed(2)} $unit" : "—",
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
