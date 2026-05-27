import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:pondstat/features/monitoring/data/finances_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/pondstat_text_field.dart';
import 'package:pondstat/core/widgets/primary_button.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:pondstat/core/widgets/discard_changes_dialog.dart';
import 'financial_total_card.dart';

class PondSaleSheet extends ConsumerStatefulWidget {
  final String pondId;

  const PondSaleSheet({super.key, required this.pondId});

  @override
  ConsumerState<PondSaleSheet> createState() => _PondSaleSheetState();
}

class _PondSaleSheetState extends ConsumerState<PondSaleSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;
  bool _forceClose = false;
  String _initialProduct = '';

  @override
  void initState() {
    super.initState();
    // Prefill product controller with pond's target species
    _prefillProduct();
  }

  Future<void> _prefillProduct() async {
    try {
      final pondDoc = await ref.read(pondRepositoryProvider).pondsCollection
          .doc(widget.pondId)
          .get();
      if (pondDoc.exists && mounted) {
        final species = pondDoc.data()?.species ?? '';
        if (species.isNotEmpty) {
          setState(() {
            _productController.text = species;
            _initialProduct = species;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _buyerController.dispose();
    _productController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _quantity {
    return double.tryParse(_quantityController.text) ?? 0.0;
  }

  double get _pricePerUnit {
    return double.tryParse(_priceController.text) ?? 0.0;
  }

  double get _totalAmount {
    return _quantity * _pricePerUnit;
  }

  bool get _hasData {
    return _buyerController.text.isNotEmpty ||
        _productController.text != _initialProduct ||
        _priceController.text.isNotEmpty ||
        _notesController.text.isNotEmpty;
  }


  Future<void> _saveSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      await ref.read(financesRepositoryProvider).addPondSale(
            pondId: widget.pondId,
            buyerName: _buyerController.text.trim(),
            productName: _productController.text.trim(),
            quantity: _quantity,
            unit: _unitController.text.trim(),
            pricePerUnit: _pricePerUnit,
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
                context, "Sale saved locally (will sync when online)");
          } else {
            SnackbarHelper.showSuccess(context, "Sale recorded successfully");
          }
          if (mounted) {
            setState(() => _forceClose = true);
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, "Error recording sale: $e");
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
          bottom: MediaQuery.of(context).padding.bottom + 32,
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
                              ? const Color(0x3310B981)
                              : const Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Record Pond Sale",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: onSurface,
                              ),
                            ),
                            const Text(
                              "Add a revenue transaction",
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
                    controller: _buyerController,
                    label: "Buyer / Wholesaler Name",
                    hint: "e.g., Local Market Dealer, Fishery Co.",
                    prefixIcon: Icons.person_outline_rounded,
                    onChanged: (_) => setState(() {}),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 16),
                  PondStatTextField(
                    controller: _productController,
                    label: "Product Name",
                    hint: "e.g., Tilapia, Shrimp",
                    prefixIcon: Icons.inventory_2_outlined,
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
                          label: "Quantity Sold",
                          hint: "1.0",
                          prefixIcon: Icons.scale_outlined,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final parsed = double.tryParse(v ?? '');
                            if (parsed == null) return "Invalid";
                            if (parsed <= 0) return "Must be > 0";
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: PondStatTextField(
                          controller: _unitController,
                          label: "Unit",
                          hint: "kg, pcs, tons",
                          prefixIcon: Icons.unfold_more_rounded,
                          onChanged: (_) => setState(() {}),
                          validator: (v) => v!.isEmpty ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PondStatTextField(
                    controller: _priceController,
                    label: "Price per Unit",
                    hint: "0.00",
                    prefixIcon: Icons.payments_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null) return "Invalid";
                      if (parsed <= 0) return "Must be > 0";
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PondStatTextField(
                    controller: _notesController,
                    label: "Notes / Remarks",
                    hint: "Optional details about this sale",
                    prefixIcon: Icons.notes_rounded,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  FinancialTotalCard(
                    label: "Total Revenue",
                    amount: _totalAmount,
                    textColor: const Color(0xFF047857),
                    backgroundColor: isDark
                        ? const Color(0x1A10B981)
                        : const Color(0x80D1FAE5),
                    borderColor: isDark
                        ? const Color(0x4D10B981)
                        : const Color(0xFFA7F3D0),
                  ),
                  const SizedBox(height: 32),
                  Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context)
                          .colorScheme
                          .copyWith(primary: const Color(0xFF10B981)),
                    ),
                    child: PrimaryButton(
                      text: 'Save Pond Sale',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveSale,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
