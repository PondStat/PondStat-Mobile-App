import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../repositories/monitoring_repository.dart';
import '../firebase/firestore_helper.dart';

class ExpensesTab extends StatelessWidget {
  final String pondId;
  final bool canAdd;

  const ExpensesTab({super.key, required this.pondId, required this.canAdd});

  @override
  Widget build(BuildContext context) {
    final repository = MonitoringRepository();

    return StreamBuilder<DocumentSnapshot>(
      stream: FirestoreHelper.pondsCollection.doc(pondId).snapshots(),
      builder: (context, pondSnapshot) {
        // Only show loader if we have NO data yet
        if (!pondSnapshot.hasData &&
            pondSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pondData =
            pondSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final roles = pondData['roles'] as Map<String, dynamic>? ?? {};

        // Count Owners and Editors only
        final groupMembers = roles.entries
            .where((e) => e.value == 'owner' || e.value == 'editor')
            .toList();
        final memberCount = groupMembers.isNotEmpty
            ? groupMembers.length
            : 1; // Avoid divide by zero

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repository.getExpensesStream(pondId),
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
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final docs = expenseSnapshot.data?.docs ?? [];
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
                        (context, index) => _buildExpenseCard(
                          context,
                          docs[index],
                          memberCount,
                          repository,
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
                        "₱${total.toStringAsFixed(2)}",
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
                      "₱${share.toStringAsFixed(2)}",
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
    MonitoringRepository repository,
  ) {
    final data = doc.data();
    final item = data['item'] ?? 'Unknown Item';
    final buyer = data['buyerName'] ?? 'Unknown';
    final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final qty = data['quantity'] ?? 1;
    final unitPrice = (data['amountPerItem'] as num?)?.toDouble() ?? 0.0;
    final share = memberCount > 0 ? total / memberCount : 0.0;
    final timestamp =
        (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.teal,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "Bought by $buyer • ${DateFormat('MMM dd').format(timestamp)}",
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (canAdd)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade300,
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () =>
                      _confirmDelete(context, doc.id, item, repository),
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
                    "₱${unitPrice.toStringAsFixed(0)}",
                  ),
                  _buildMetric(
                    "Total",
                    "₱${total.toStringAsFixed(0)}",
                    isBold: true,
                  ),
                  _buildMetric(
                    "Share",
                    "₱${share.toStringAsFixed(0)}",
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: isPrimary ? Colors.teal : const Color(0xFF1E293B),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_rounded,
              size: 64,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              "No expenses recorded yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    String id,
    String item,
    MonitoringRepository repository,
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
              await repository.deleteExpense(id);
              if (context.mounted) Navigator.pop(context);
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
