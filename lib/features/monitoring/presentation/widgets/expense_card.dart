import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'card_metric.dart';

class ExpenseCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final int memberCount;
  final bool canDelete;
  final VoidCallback onDelete;

  const ExpenseCard({
    super.key,
    required this.data,
    required this.memberCount,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final item = data['item'] ?? 'Unknown Item';
    final buyer = data['buyerName'] ?? 'Unknown';
    final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final qty = data['quantity'] ?? 1;
    final unitPrice = (data['amountPerItem'] as num?)?.toDouble() ?? 0.0;
    final share = memberCount > 0 ? total / memberCount : 0.0;
    final ts = data['timestamp'] as Timestamp?;
    final timestamp = ts?.toDate() ?? DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    final compactCurrencyFormat = NumberFormat.currency(
      symbol: '₱',
      decimalDigits: 0,
    );

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
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? Colors.teal.withValues(alpha: 0.2)
                    : Colors.teal.shade100,
                foregroundColor: Colors.teal.shade700,
                child: Text(
                  buyer.isNotEmpty ? buyer[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                      "Bought by $buyer • ${DateFormat('MMM dd').format(timestamp)}",
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CardMetric(
                  label: "Qty",
                  value: qty.toString(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CardMetric(
                  label: "Unit Price",
                  value: compactCurrencyFormat.format(unitPrice),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CardMetric(
                  label: "Total",
                  value: compactCurrencyFormat.format(total),
                  isHighlighted: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CardMetric(
                  label: "Share",
                  value: compactCurrencyFormat.format(share),
                  isHighlighted: true,
                  valueColor: Colors.teal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
