import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'card_metric.dart';

class PondSaleCard extends StatelessWidget {
  final String id;
  final String buyerName;
  final String productName;
  final String recordedByName;
  final double totalAmount;
  final double quantity;
  final String unit;
  final double pricePerUnit;
  final DateTime timestamp;
  final String notes;
  final bool canDelete;
  final VoidCallback onDelete;

  const PondSaleCard({
    super.key,
    required this.id,
    required this.buyerName,
    required this.productName,
    required this.recordedByName,
    required this.totalAmount,
    required this.quantity,
    required this.unit,
    required this.pricePerUnit,
    required this.timestamp,
    required this.notes,
    this.canDelete = true,
    required this.onDelete,
  });

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
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFFD1FAE5),
                foregroundColor: const Color(0xFF047857),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "$productName • Sold by $recordedByName • ${DateFormat('MMM dd').format(timestamp)}",
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
                label: "Price/Unit",
                value: compactCurrencyFormat.format(pricePerUnit),
              ),
              CardMetric(
                label: "Total Sale",
                value: compactCurrencyFormat.format(totalAmount),
                isHighlighted: true,
                valueColor: const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
