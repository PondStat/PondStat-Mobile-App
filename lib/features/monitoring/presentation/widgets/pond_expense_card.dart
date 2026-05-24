import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'card_metric.dart';

class PondExpenseCard extends StatelessWidget {
  final String id;
  final String item;
  final String category;
  final String recordedByName;
  final double totalAmount;
  final double quantity;
  final String unit;
  final double amountPerUnit;
  final DateTime timestamp;
  final String notes;
  final bool canDelete;
  final VoidCallback onDelete;

  const PondExpenseCard({
    super.key,
    required this.id,
    required this.item,
    required this.category,
    required this.recordedByName,
    required this.totalAmount,
    required this.quantity,
    required this.unit,
    required this.amountPerUnit,
    required this.timestamp,
    required this.notes,
    this.canDelete = true,
    required this.onDelete,
  });

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Feed':
        return Icons.eco_rounded;
      case 'Seed':
        return Icons.water_drop_rounded;
      case 'Fertilizer':
        return Icons.grass_rounded;
      case 'Labor':
        return Icons.engineering_rounded;
      case 'Medicine':
        return Icons.medication_rounded;
      case 'Equipment':
        return Icons.handyman_rounded;
      case 'Utilities':
        return Icons.bolt_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;
    final compactCurrencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? Colors.indigo.withValues(alpha: 0.2)
                    : Colors.indigo.shade100,
                foregroundColor: Colors.indigo.shade700,
                child: Icon(
                  _getCategoryIcon(category),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "$category • Logged by $recordedByName • ${DateFormat('MMM dd').format(timestamp)}",
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (canDelete)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade300,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: onDelete,
                ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                ),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CardMetric(
                label: "Quantity",
                value: "$quantity $unit",
              ),
              CardMetric(
                label: "Unit Price",
                value: compactCurrencyFormat.format(amountPerUnit),
              ),
              CardMetric(
                label: "Total Cost",
                value: compactCurrencyFormat.format(totalAmount),
                isHighlighted: true,
                valueColor: Colors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
