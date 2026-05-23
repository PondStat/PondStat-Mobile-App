import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';
import 'package:pondstat/features/monitoring/data/monitoring_repository.dart';
import 'package:pondstat/core/utils/snackbar_helper.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/destructive_dialog.dart';

class PondSalesTab extends ConsumerStatefulWidget {
  final String pondId;
  final bool canAdd;

  const PondSalesTab({super.key, required this.pondId, required this.canAdd});

  @override
  ConsumerState<PondSalesTab> createState() => _PondSalesTabState();
}

class _PondSalesTabState extends ConsumerState<PondSalesTab> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _salesStream;

  void _initStreams() {
    _salesStream = ref.read(monitoringRepositoryProvider).getPondSalesStream(widget.pondId);
  }

  Future<void> _refreshData() async {
    setState(() {
      _initStreams();
    });
    try {
      await _salesStream.first.timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  @override
  void didUpdateWidget(covariant PondSalesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _initStreams();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _salesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder(message: "Loading pond sales...");
        }

        if (snapshot.hasError) {
          return ErrorStateCard(
            description: "Error loading sales: ${snapshot.error}",
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

        double totalRevenue = 0;
        final Map<String, double> volumesByUnit = {};

        for (var doc in docs) {
          final data = doc.data();
          totalRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          final double qty = (data['quantity'] as num?)?.toDouble() ?? 0.0;
          final String unit = data['unit']?.toString().trim() ?? 'kg';
          if (qty > 0) {
            volumesByUnit[unit] = (volumesByUnit[unit] ?? 0.0) + qty;
          }
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
                  child: _buildSummaryCard(totalRevenue, volumesByUnit),
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
                        child: _buildSaleCard(context, docs[index]),
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
  }

  Widget _buildSummaryCard(double totalRevenue, Map<String, double> volumesByUnit) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    final List<String> volumeStrings = [];
    volumesByUnit.forEach((unit, volume) {
      volumeStrings.add("${volume.toStringAsFixed(1)} $unit");
    });
    final String volumeText = volumeStrings.isEmpty ? "0.0 kg" : volumeStrings.join(", ");

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withValues(alpha: 0.3),
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
                      "TOTAL SALES REVENUE",
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
                        currencyFormat.format(totalRevenue),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.scale_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      volumeText,
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
        ],
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final buyer = data['buyerName'] ?? 'Unknown Buyer';
    final product = data['productName'] ?? 'Harvested Fish';
    final seller = data['recordedByName'] ?? 'Unknown';
    final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final qty = (data['quantity'] as num?)?.toDouble() ?? 1.0;
    final unit = data['unit'] ?? 'kg';
    final pricePerUnit = (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0;
    final ts = data['timestamp'] as Timestamp?;
    final timestamp = ts?.toDate() ?? DateTime.now();
    final notes = data['notes'] ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = colorScheme.onSurface;

    final compactCurrencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 0);

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFFD1FAE5),
                foregroundColor: const Color(0xFF047857),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyer,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "$product • Sold by $seller • ${DateFormat('MMM dd').format(timestamp)}",
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
                  onPressed: () => _confirmDelete(context, doc.id, buyer),
                ),
            ],
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200,
                ),
              ),
              child: Text(
                notes,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric("Quantity", "${qty.toString()} $unit"),
              _buildMetric("Price/Unit", compactCurrencyFormat.format(pricePerUnit)),
              _buildMetric(
                "Total Sale",
                compactCurrencyFormat.format(total),
                isBold: true,
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {bool isBold = false, bool isPrimary = false}) {
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
            color: isPrimary ? const Color(0xFF10B981) : colorScheme.onSurface,
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
        padding: const EdgeInsets.all(24.0),
        child: EmptyStateCard(
          image: const Icon(Icons.monetization_on_rounded),
          title: "No sales records",
          description: "Tap 'Add Sale' to log revenue.",
          scrollable: false,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String buyer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DestructiveDialog(
        title: "Delete Sales Record?",
        content: "Are you sure you want to remove the sale to '$buyer'? This action cannot be undone.",
        onConfirm: () async {
          await ref.read(monitoringRepositoryProvider).deletePondSale(id);
          HapticFeedback.mediumImpact();
          if (context.mounted) {
            SnackbarHelper.showSuccess(context, "Sales record deleted");
          }
        },
      ),
    );
  }
}
