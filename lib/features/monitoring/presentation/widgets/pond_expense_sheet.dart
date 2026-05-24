import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/pondstat_dropdown_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/core/widgets/discard_changes_dialog.dart';

class PondExpenseSheet extends ConsumerStatefulWidget {
  final String pondId;

  const PondExpenseSheet({super.key, required this.pondId});

  @override
  ConsumerState<PondExpenseSheet> createState() => _PondExpenseSheetState();
}

class _PondExpenseSheetState extends ConsumerState<PondExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Feed';
  final List<String> _categories = [
    'Feed',
    'Seed',
    'Fertilizer',
    'Labor',
    'Medicine',
    'Equipment',
    'Utilities',
    'Other',
  ];

  bool _isSaving = false;
  bool _forceClose = false;

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _quantity {
    return double.tryParse(_quantityController.text) ?? 0.0;
  }

  double get _amountPerUnit {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  double get _totalAmount {
    return _quantity * _amountPerUnit;
  }

  bool get _hasData {
    return _itemController.text.isNotEmpty ||
        _amountController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;
  }

  bool get _isValid {
    return _itemController.text.trim().isNotEmpty &&
        _selectedCategory.isNotEmpty &&
        _quantity > 0 &&
        _amountPerUnit > 0;
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(monitoringRepositoryProvider).addPondExpense(
            pondId: widget.pondId,
            category: _selectedCategory,
            item: _itemController.text.trim(),
            quantity: _quantity,
            unit: _unitController.text.trim(),
            amountPerUnit: _amountPerUnit,
            totalAmount: _totalAmount,
            notes: _notesController.text.trim(),
          );

      if (mounted) {
        final connectivityResult = await Connectivity().checkConnectivity().timeout(
              const Duration(seconds: 1),
              onTimeout: () => [ConnectivityResult.none],
            );
        if (mounted) {
          if (connectivityResult.contains(ConnectivityResult.none)) {
            SnackbarHelper.showSuccess(
                context, "Pond expense saved locally (will sync when online)");
          } else {
            SnackbarHelper.showSuccess(context, "Pond expense recorded successfully");
          }
          if (mounted) {
            setState(() => _forceClose = true);
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Error recording pond expense: $e");
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
        builder: (context) => const DiscardChangesDialog(
          title: 'Discard unsaved changes?',
          content: 'Are you sure you want to discard your changes?',
          cancelText: 'CANCEL',
          confirmText: 'DISCARD',
        ),
      );

      if (shouldPop == true && mounted) {
        setState(() => _forceClose = true);
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return PopScope(
      canPop: !_hasData || _forceClose,
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
                              ? Colors.indigo.withValues(alpha: 0.2)
                              : Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_rounded,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Record Pond Expense",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                              ),
                            ),
                            const Text(
                              "Add a direct operational cost",
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
                  PondStatDropdownField<String>(
                    value: _selectedCategory,
                    label: "Category",
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    prefixIcon: Icons.category_outlined,
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _selectedCategory = v;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  PondStatTextField(
                    controller: _itemController,
                    label: "Item Name / Description",
                    hint: "e.g., Breeder Feed, Aerator Pump, Probiotics",
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
                          hint: "1.0",
                          prefixIcon: Icons.production_quantity_limits_rounded,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) =>
                              double.tryParse(v ?? '') == null ? "Invalid" : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PondStatTextField(
                          controller: _unitController,
                          label: "Unit",
                          hint: "kg, bags, pcs",
                          prefixIcon: Icons.unfold_more_rounded,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PondStatTextField(
                    controller: _amountController,
                    label: "Price per Unit",
                    hint: "0.00",
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) =>
                        double.tryParse(v ?? '') == null ? "Invalid" : null,
                  ),
                  const SizedBox(height: 16),
                  PondStatTextField(
                    controller: _notesController,
                    label: "Notes / Remarks",
                    hint: "Optional details about this expense",
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  _buildTotalCard(isDark),
                  const SizedBox(height: 32),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context)
                          .colorScheme
                          .copyWith(primary: Colors.indigo),
                    ),
                    child: PrimaryButton(
                      text: 'Save Pond Expense',
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
            ? Colors.indigo.withValues(alpha: 0.1)
            : Colors.indigo.shade50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.indigo.withValues(alpha: 0.3)
              : Colors.indigo.shade100,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Total Amount",
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.indigo,
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
              color: Colors.indigo,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}
