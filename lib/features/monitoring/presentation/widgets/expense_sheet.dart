import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/utils/helpers.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';

class ExpenseSheet extends ConsumerStatefulWidget {
  final String pondId;

  const ExpenseSheet({super.key, required this.pondId});

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _amountController = TextEditingController();

  bool _isSaving = false;

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

  bool get _hasData {
    return _itemController.text.isNotEmpty || _amountController.text.isNotEmpty;
  }

  bool get _isValid {
    return _itemController.text.trim().isNotEmpty && _totalAmount > 0;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(monitoringRepositoryProvider).addExpense(
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

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;

    if (_hasData) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved expense?'),
          content: const Text('Are you sure you want to discard your changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('DISCARD', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldPop == true && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: !_hasData,
      onPopInvokedWithResult: (didPop, result) => _onPopInvoked(didPop),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          top: 12,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
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
                        color: isDark ? Colors.white10 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.teal.withValues(alpha: 0.2)
                              : Colors.teal.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Record Expense",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                              ),
                            ),
                            const Text(
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
                        onPressed: () {
                          if (_hasData) {
                            _onPopInvoked(false);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),
                  PondStatTextField(
                    controller: _itemController,
                    label: "Item Name",
                    hint: "e.g., Fish Feed, Pump Repair",
                    prefixIcon: Icons.shopping_bag_outlined,
                    onChanged: (_) => setState(() {}),
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
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
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
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) => double.tryParse(v ?? '') == null
                              ? "Invalid"
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildTotalCard(isDark),

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
                      onPressed: _isValid ? _saveExpense : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.teal.withValues(alpha: 0.1)
            : Colors.teal.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.teal.withValues(alpha: 0.3)
              : Colors.teal.shade100,
        ),
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
            NumberFormat.currency(
              symbol: '₱',
              decimalDigits: 2,
            ).format(_totalAmount),
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
