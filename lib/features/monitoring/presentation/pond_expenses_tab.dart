import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_expense_card.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_financial_summary_card.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';
import 'package:pondstat/features/monitoring/data/finances_repository.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/destructive_dialog.dart';

class PondExpensesTab extends ConsumerStatefulWidget {
  final String pondId;
  final bool canAdd;

  const PondExpensesTab({super.key, required this.pondId, required this.canAdd});

  @override
  ConsumerState<PondExpensesTab> createState() => _PondExpensesTabState();
}

class _PondExpensesTabState extends ConsumerState<PondExpensesTab> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _expensesStream;

  void _initStreams() {
    _expensesStream = ref.read(financesRepositoryProvider).getPondExpensesStream(widget.pondId);
  }

  Future<void> _refreshData() async {
    setState(() {
      _initStreams();
    });
    try {
      await _expensesStream.first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant PondExpensesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _initStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder(message: "Loading pond expenses...");
        }

        if (snapshot.hasError) {
          return ErrorStateCard(
            description: "Error loading expenses: ${snapshot.error}",
            onRetry: _refreshData,
          );
        }

        final unsortedDocs = snapshot.data?.docs ?? [];
        final docs = unsortedDocs.toList()
          ..sort((a, b) {
            final tA = a.data()['timestamp'] as Timestamp?;
            final tB = b.data()['timestamp'] as Timestamp?;
            if (tA == null || tB == null) return 0;
            return tB.compareTo(tA);
          });

        double totalSpend = 0;
        for (var doc in docs) {
          totalSpend += (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
        }

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: PondFinancialSummaryCard(
                    label: "TOTAL POND EXPENSES",
                    totalAmount: totalSpend,
                    gradientColors: const [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    secondaryIcon: Icons.receipt_long_rounded,
                    secondaryText: "${docs.length} ${docs.length == 1 ? 'Item' : 'Items'}",
                  ),
                ),
              ),
              if (docs.isEmpty)
                _buildEmptyState()
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final ts = data['timestamp'] as Timestamp?;
                        return StaggeredListItem(
                          index: index,
                          child: PondExpenseCard(
                            id: doc.id,
                            item: data['item'] ?? 'Unknown Item',
                            category: data['category'] ?? 'Other',
                            recordedByName: data['recordedByName'] ?? 'Unknown',
                            totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
                            quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
                            unit: data['unit'] ?? 'kg',
                            amountPerUnit: (data['amountPerUnit'] as num?)?.toDouble() ?? 0.0,
                            timestamp: ts?.toDate() ?? DateTime.now(),
                            notes: data['notes'] ?? '',
                            canDelete: widget.canAdd,
                            onDelete: () => _confirmDelete(context, doc.id, data['item'] ?? 'Unknown Item'),
                          ),
                        );
                      },
                      childCount: docs.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: EmptyStateCard(
          image: const Icon(Icons.receipt_long_rounded),
          title: "No direct expenses records",
          description: "Tap 'Add Pond Expense' to log direct costs.",
          scrollable: false,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String item) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestructiveDialog(
        title: "Delete Pond Expense?",
        content: "Are you sure you want to remove '$item'? This action cannot be undone.",
        onConfirm: () async {
          await ref.read(financesRepositoryProvider).deletePondExpense(id);
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, "Pond expense deleted");
          }
        },
      ),
    );
  }
}
