import 'package:flutter/material.dart';
import 'package:pondstat/features/monitoring/presentation/expenses_tab.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/expense_sheet.dart';

class ExpensesPage extends StatelessWidget {
  final String pondId;
  final bool canEdit;

  const ExpensesPage({super.key, required this.pondId, required this.canEdit});

  void _showExpenseOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExpenseSheet(pondId: pondId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ExpensesTab(pondId: pondId, canAdd: canEdit),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () => _showExpenseOverlay(context),
              backgroundColor: Colors.teal,
              icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
              label: const Text("Add Expense", style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }
}
