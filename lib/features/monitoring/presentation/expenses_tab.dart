import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/expense_card.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';
import 'package:pondstat/features/monitoring/data/finances_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/destructive_dialog.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/expense_summary_card.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  final String pondId;
  final bool canAdd;

  const ExpensesTab({super.key, required this.pondId, required this.canAdd});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  late Stream<DocumentSnapshot<Pond>> _pondStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _expensesStream;

  void _initStreams() {
    _pondStream = ref.read(pondRepositoryProvider).pondsCollection
        .doc(widget.pondId)
        .snapshots();
    _expensesStream = ref.read(financesRepositoryProvider).getExpensesStream(widget.pondId);
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
  void didUpdateWidget(covariant ExpensesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _initStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Pond>>(
      stream: _pondStream,
      builder: (context, pondSnapshot) {
        if (pondSnapshot.hasError) {
          return ErrorStateCard(
            description: "Error loading pond data: ${pondSnapshot.error}",
            onRetry: _refreshData,
          );
        }

        // Only show loader if we have NO data yet
        if (!pondSnapshot.hasData &&
            pondSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder(message: "Loading pond details...");
        }

        final pond = pondSnapshot.data?.data();
        final roles = pond?.roles ?? {};

        // Count Owners and Editors only
        final groupMembers = roles.entries
            .where((e) => e.value == 'owner' || e.value == 'editor')
            .toList();
        final memberCount = groupMembers.isNotEmpty
            ? groupMembers.length
            : 1; // Avoid divide by zero

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            // Only show loader if we have NO data yet
            if (!expenseSnapshot.hasData &&
                expenseSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingPlaceholder(message: "Loading expenses...");
            }

            if (expenseSnapshot.hasError) {
              return ErrorStateCard(
                description: "Error loading expenses: ${expenseSnapshot.error}",
                onRetry: _refreshData,
              );
            }

            final unsortedDocs = expenseSnapshot.data?.docs ?? [];
            final docs = unsortedDocs.toList()
              ..sort((a, b) {
                final tA = a.data()['timestamp'] as Timestamp?;
                final tB = b.data()['timestamp'] as Timestamp?;
                if (tA == null || tB == null) return 0;
                return tB.compareTo(tA);
              });
            double totalGroupSpend = 0;
            for (var doc in docs) {
              totalGroupSpend +=
                  (doc.data()['totalAmount'] as num?)?.toDouble() ?? 0.0;
            }

            final splitShare = totalGroupSpend / memberCount;

            return RefreshIndicator(
              onRefresh: _refreshData,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: ExpenseSummaryCard(
                      total: totalGroupSpend,
                      members: memberCount,
                      share: splitShare,
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
                        (context, index) => StaggeredListItem(
                          index: index,
                          child: ExpenseCard(
                            data: docs[index].data(),
                            memberCount: memberCount,
                            canDelete: widget.canAdd,
                            onDelete: () => _confirmDelete(
                              context,
                              docs[index].id,
                              docs[index].data()['item'] ?? 'Unknown Item',
                            ),
                          ),
                        ),
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
      },
    );
  }



  Widget _buildEmptyState() {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: EmptyStateCard(
          image: const Icon(Icons.receipt_long_rounded),
          title: "No group expenses records",
          description: "Tap 'Add Expenses' to log an expense.",
          scrollable: false,
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String id,
    String item,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestructiveDialog(
        title: "Delete Expense?",
        content: "Are you sure you want to remove '$item'? This action cannot be undone.",
        onConfirm: () async {
          await ref.read(financesRepositoryProvider).deleteExpense(id);
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, "Expense deleted");
          }
        },
      ),
    );
  }
}
