import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_sale_card.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/pond_financial_summary_card.dart';
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

        final List<String> volumeStrings = [];
        volumesByUnit.forEach((unit, volume) {
          volumeStrings.add("${volume.toStringAsFixed(1)} $unit");
        });
        final String volumeText = volumeStrings.isEmpty ? "0.0 kg" : volumeStrings.join(", ");

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
                    label: "TOTAL SALES REVENUE",
                    totalAmount: totalRevenue,
                    gradientColors: const [Color(0xFF065F46), Color(0xFF10B981)],
                    secondaryIcon: Icons.scale_rounded,
                    secondaryText: volumeText,
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
                          child: PondSaleCard(
                            id: doc.id,
                            buyerName: data['buyerName'] ?? 'Unknown Buyer',
                            productName: data['productName'] ?? 'Harvested Fish',
                            recordedByName: data['recordedByName'] ?? 'Unknown',
                            totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
                            quantity: (data['quantity'] as num?)?.toDouble() ?? 1.0,
                            unit: data['unit'] ?? 'kg',
                            pricePerUnit: (data['pricePerUnit'] as num?)?.toDouble() ?? 0.0,
                            timestamp: ts?.toDate() ?? DateTime.now(),
                            notes: data['notes'] ?? '',
                            canDelete: widget.canAdd,
                            onDelete: () => _confirmDelete(context, doc.id, data['buyerName'] ?? 'Unknown Buyer'),
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
  }  Widget _buildEmptyState() {
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
