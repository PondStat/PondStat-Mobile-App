import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class ExpenseSheet extends StatefulWidget {
  final String pondId;

  const ExpenseSheet({super.key, required this.pondId});

  @override
  State<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends State<ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _amountController = TextEditingController();

  bool _isSaving = false;
  final MonitoringRepository _repository = MonitoringRepository();

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    final qty = int.tryParse(_quantityController.text) ?? 0;
    final amt = double.tryParse(_amountController.text) ?? 0.0;
    return qty * amt;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await _repository.addExpense(
        pondId: widget.pondId,
        item: _itemController.text.trim(),
        quantity: int.parse(_quantityController.text),
        amountPerItem: double.parse(_amountController.text),
        totalAmount: _totalAmount,
      );

      if (mounted) {
        Navigator.pop(context, true);
        SnackbarHelper.show(
          context,
          "Expense recorded successfully",
          backgroundColor: Colors.green.shade600,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          "Error recording expense: $e",
          backgroundColor: Colors.redAccent,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Record Expense",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          "Add a new group expenditure",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              PondStatTextField(
                controller: _itemController,
                label: "Item Name",
                hint: "e.g., Fish Feed, Pump Repair",
                prefixIcon: Icons.shopping_bag_outlined,
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: PondStatTextField(
                      controller: _quantityController,
                      label: "Quantity",
                      hint: "1",
                      prefixIcon: Icons.production_quantity_limits_rounded,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          int.tryParse(v ?? '') == null ? "Invalid" : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: PondStatTextField(
                      controller: _amountController,
                      label: "Price per Item",
                      hint: "0.00",
                      prefixIcon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) =>
                          double.tryParse(v ?? '') == null ? "Invalid" : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              _buildTotalCard(),

              const SizedBox(height: 32),

              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(
                    context,
                  ).colorScheme.copyWith(primary: Colors.teal),
                ),
                child: PrimaryButton(
                  text: 'Save Expense',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isSaving,
                  onPressed: _saveExpense,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Amount",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.teal,
              fontSize: 16,
            ),
          ),
          Text(
            "₱${_totalAmount.toStringAsFixed(2)}",
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.teal,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
