import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FinancialTotalCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const FinancialTotalCard({
    super.key,
    required this.label,
    required this.amount,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: textColor,
              fontSize: 16,
            ),
          ),
          Text(
            NumberFormat.currency(
              symbol: '₱',
              decimalDigits: 2,
            ).format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: textColor,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
