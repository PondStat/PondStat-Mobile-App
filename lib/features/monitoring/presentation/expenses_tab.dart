import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';

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

  @override
  void initState() {
    super.initState();
    _pondStream = ref.read(pondRepositoryProvider).pondsCollection
        .doc(widget.pondId)
        .snapshots();
    _expensesStream = ref.read(monitoringRepositoryProvider).getExpensesStream(widget.pondId);
  }

  @override
  void didUpdateWidget(covariant ExpensesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _pondStream = ref.read(pondRepositoryProvider).pondsCollection
          .doc(widget.pondId)
          .snapshots();
      _expensesStream = ref.read(monitoringRepositoryProvider).getExpensesStream(widget.pondId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Pond>>(
      stream: _pondStream,
      builder: (context, pondSnapshot) {
        // Only show loader if we have NO data yet
        if (!pondSnapshot.hasData &&
            pondSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
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
              return const Center(child: CircularProgressIndicator());
            }

            if (expenseSnapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    "Error loading expenses:\n${expenseSnapshot.error}",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverToBoxAdapter(
                    child: _buildSummaryCard(
                      totalGroupSpend,
                      memberCount,
                      splitShare,
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
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryCard(double total, int members, double share) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "TOTAL GROUP SPEND",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        currencyFormat.format(total),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.group_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$members ${members == 1 ? 'Member' : 'Members'}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Individual Share",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      currencyFormat.format(share),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Delete Expense?",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text("Are you sure you want to remove '$item'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(monitoringRepositoryProvider).deleteExpense(id);
              if (context.mounted) {
                HapticFeedback.mediumImpact();
                SnackbarHelper.showSuccess(context, "Expense deleted");
                Navigator.pop(context);
              }
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
