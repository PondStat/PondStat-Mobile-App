import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
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
    _expensesStream = ref.read(monitoringRepositoryProvider).getExpensesStream(widget.pondId);
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
                          child: _buildExpenseCard(
                            context,
                            docs[index],
                            memberCount,
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



  Widget _buildExpenseCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int memberCount,
  ) {
    final data = doc.data();
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
              if (widget.canAdd)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade300,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _confirmDelete(context, doc.id, item),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetric("Qty", qty.toString()),
                  _buildMetric(
                    "Unit Price",
                    compactCurrencyFormat.format(unitPrice),
                  ),
                  _buildMetric(
                    "Total",
                    compactCurrencyFormat.format(total),
                    isBold: true,
                  ),
                  _buildMetric(
                    "Share",
                    compactCurrencyFormat.format(share),
                    isPrimary: true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    String label,
    String value, {
    bool isBold = false,
    bool isPrimary = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? Colors.teal : colorScheme.onSurface,
            fontWeight: isBold || isPrimary ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
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
          await ref.read(monitoringRepositoryProvider).deleteExpense(id);
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, "Expense deleted");
          }
        },
      ),
    );
  }
}
