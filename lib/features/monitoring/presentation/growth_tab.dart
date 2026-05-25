import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/growth_metric_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/data/growth_repository.dart';
import 'package:pondstat/features/dashboard/data/pond_repository.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/core/widgets/empty_state_card.dart';
import 'package:pondstat/core/widgets/staggered_list_item.dart';
import 'package:pondstat/core/widgets/loading_placeholder.dart';
import 'package:pondstat/core/widgets/error_state_card.dart';

class GrowthTab extends ConsumerStatefulWidget {
  final String pondId;
  final bool canEdit;
  final void Function(GrowthMetrics) onEdit;
  final void Function(GrowthMetrics) onDelete;

  const GrowthTab({
    super.key,
    required this.pondId,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  ConsumerState<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends ConsumerState<GrowthTab> {
  late Future<List<GrowthMetrics>> _growthMetricsFuture;
  late Stream<DocumentSnapshot<Pond>> _pondStream;
  double? _customTargetAbw;
  double? _customSurvivalRate;
  bool _showProjectionSettings = false;

  @override
  void initState() {
    super.initState();
    _growthMetricsFuture = ref.read(growthRepositoryProvider).calculateGrowthMetrics(
      widget.pondId,
    );
    _pondStream = ref.read(pondRepositoryProvider).pondsCollection
        .doc(widget.pondId)
        .snapshots();
  }

  @override
  void didUpdateWidget(covariant GrowthTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pondId != widget.pondId) {
      _customTargetAbw = null;
      _customSurvivalRate = null;
      _showProjectionSettings = false;
      _growthMetricsFuture = ref.read(growthRepositoryProvider).calculateGrowthMetrics(
        widget.pondId,
      );
      _pondStream = ref.read(pondRepositoryProvider).pondsCollection
          .doc(widget.pondId)
          .snapshots();
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _growthMetricsFuture = ref.read(growthRepositoryProvider).calculateGrowthMetrics(
        widget.pondId,
      );
      _pondStream = ref.read(pondRepositoryProvider).pondsCollection
          .doc(widget.pondId)
          .snapshots();
    });
    await _growthMetricsFuture;
  }

  double _getFeedingRatePercentage(String species, double abw) {
    final cleanSpecies = species.trim().toLowerCase();
    if (cleanSpecies == 'tilapia') {
      if (abw < 1.0) return 20.0;
      if (abw <= 5.0) return 8.0;
      if (abw <= 20.0) return 5.0;
      if (abw <= 100.0) return 3.5;
      return 2.25;
    } else if (cleanSpecies == 'shrimp') {
      if (abw < 1.0) return 9.0;
      if (abw <= 3.0) return 7.5;
      if (abw <= 5.0) return 6.25;
      if (abw <= 10.0) return 4.75;
      if (abw <= 15.0) return 3.5;
      if (abw <= 20.0) return 2.75;
      return 2.25;
    }
    return 3.0; // Default fallback
  }

  Widget _buildAutoFeedCard(BuildContext context, Pond pond, List<GrowthMetrics> metrics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (metrics.isEmpty) return const SizedBox.shrink();
    final latestMetric = metrics.first;
    final abw = latestMetric.abw;
    
    if (abw == null || abw <= 0) {
      return const SizedBox.shrink();
    }

    final stockingQuantity = pond.stockingQuantity;
    final species = pond.species.isNotEmpty ? pond.species : 'Unspecified';

    if (stockingQuantity <= 0) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  "Auto-Feed Recommendation",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Stocking quantity is not configured for this pond. Please edit pond details to calculate auto-feed recommendations.",
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final feedingRatePercent = _getFeedingRatePercentage(species, abw);
    final recommendedFeedKg = (abw * stockingQuantity * feedingRatePercent) / 100000.0;

    final dfr = latestMetric.dfr;
    String statusTitle = "Optimal";
    Color statusColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
    Color statusBg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
    IconData statusIcon = Icons.check_circle_rounded;
    String comparisonMessage = "";

    if (dfr != null && dfr > 0) {
      final ratio = dfr / recommendedFeedKg;
      if (ratio > 1.1) {
        statusTitle = "Overfeeding Warning";
        statusColor = isDark ? Colors.red.shade300 : Colors.red.shade700;
        statusBg = isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.shade50;
        statusIcon = Icons.warning_rounded;
        final percentage = ((ratio - 1.0) * 100).toStringAsFixed(0);
        comparisonMessage = "Logged DFR is $percentage% above recommendation. Overfeeding increases FCR and degrades water quality.";
      } else if (ratio < 0.9) {
        statusTitle = "Underfeeding Warning";
        statusColor = isDark ? Colors.orange.shade300 : Colors.orange.shade700;
        statusBg = isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
        statusIcon = Icons.info_outline_rounded;
        final percentage = ((1.0 - ratio) * 100).toStringAsFixed(0);
        comparisonMessage = "Logged DFR is $percentage% below recommendation. Underfeeding may slow down growth.";
      } else {
        statusTitle = "Optimal Feeding";
        statusColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
        statusBg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
        statusIcon = Icons.check_circle_rounded;
        comparisonMessage = "Logged DFR matches the recommendation. Great job maintaining an optimal FCR!";
      }
    } else {
      statusTitle = "Recommendation Ready";
      statusColor = isDark ? Colors.blue.shade300 : Colors.blue.shade700;
      statusBg = isDark ? Colors.blue.withValues(alpha: 0.15) : Colors.blue.shade50;
      statusIcon = Icons.lightbulb_rounded;
      comparisonMessage = "Use this recommendation to log your Daily Feed Requirement (DFR) this week.";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              color: statusColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.restaurant_menu_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Auto-Feed Recommendation",
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              statusTitle,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "RECOMMENDED DAILY FEED",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  recommendedFeedKg.toStringAsFixed(2),
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 32,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "kg/day",
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 50,
                        width: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow(
                              "Species", 
                              species,
                              colorScheme,
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              "Current ABW", 
                              "${abw.toStringAsFixed(1)}g",
                              colorScheme,
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              "Stocking Qty", 
                              NumberFormat('#,###').format(stockingQuantity),
                              colorScheme,
                            ),
                            const SizedBox(height: 4),
                            _buildInfoRow(
                              "Feeding Rate", 
                              "${feedingRatePercent.toStringAsFixed(2)}%",
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusBg.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          statusIcon,
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (dfr != null && dfr > 0)
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurface,
                                      fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                                    ),
                                    children: [
                                      const TextSpan(text: "Recorded DFR: "),
                                      TextSpan(
                                        text: "${dfr.toStringAsFixed(2)} kg/day",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const TextSpan(text: " vs. Recommended: "),
                                      TextSpan(
                                        text: "${recommendedFeedKg.toStringAsFixed(2)} kg/day",
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              if (dfr != null && dfr > 0) const SizedBox(height: 4),
                              Text(
                                comparisonMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildHarvestProjectionCard(BuildContext context, Pond pond, List<GrowthMetrics> metrics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (metrics.isEmpty) return const SizedBox.shrink();
    final latestMetric = metrics.first;
    final abw = latestMetric.abw;
    if (abw == null || abw <= 0) {
      return const SizedBox.shrink();
    }

    final species = pond.species.trim().toLowerCase();
    double defaultTargetAbw = 300.0;
    double defaultSurvivalRate = 0.80;
    double defaultAdg = 1.5;

    if (species == 'tilapia') {
      defaultTargetAbw = 450.0;
      defaultSurvivalRate = 0.85;
      defaultAdg = 2.5;
    } else if (species == 'shrimp') {
      defaultTargetAbw = 25.0;
      defaultSurvivalRate = 0.75;
      defaultAdg = 0.3;
    }

    final targetAbw = _customTargetAbw ?? defaultTargetAbw;
    final survivalRate = _customSurvivalRate ?? defaultSurvivalRate;

    // Get rolling ADG trend (average of last 3 positive recorded ADGs)
    final validAdgs = metrics
        .map((m) => m.adg)
        .whereType<double>()
        .where((val) => val > 0)
        .toList();

    double adgTrend;
    bool isFallbackAdg = false;

    if (validAdgs.isEmpty) {
      adgTrend = defaultAdg;
      isFallbackAdg = true;
    } else {
      final recent = validAdgs.take(3).toList();
      adgTrend = recent.reduce((a, b) => a + b) / recent.length;
    }

    final double currentAbw = abw;
    DateTime predictedDate;
    int remainingDays = 0;
    bool isReadyForHarvest = currentAbw >= targetAbw;

    if (isReadyForHarvest) {
      predictedDate = latestMetric.date;
      remainingDays = 0;
    } else {
      final double weightNeeded = targetAbw - currentAbw;
      final double daysNeeded = weightNeeded / adgTrend;
      predictedDate = latestMetric.date.add(Duration(days: daysNeeded.round()));
      remainingDays = predictedDate.difference(DateTime.now()).inDays;
      if (remainingDays < 0) {
        remainingDays = 0;
        isReadyForHarvest = true;
      }
    }

    final stockingQuantity = pond.stockingQuantity;
    final double estimatedSurvivalCount = stockingQuantity * survivalRate;
    final double estimatedYieldKg = (targetAbw * estimatedSurvivalCount) / 1000.0;
    final String yieldDisplay = stockingQuantity > 0 
        ? "${NumberFormat('#,###').format(estimatedYieldKg.round())} kg" 
        : "N/A (Set Stocking Qty)";

    final double progress = (currentAbw / targetAbw).clamp(0.0, 1.0);
    final String progressPercentStr = (progress * 100).toStringAsFixed(0);

    String statusTitle = "Growing";
    Color statusColor = colorScheme.primary;
    Color statusBg = colorScheme.primary.withValues(alpha: 0.1);
    IconData statusIcon = Icons.trending_up_rounded;

    if (isReadyForHarvest) {
      statusTitle = "Ready for Harvest";
      statusColor = isDark ? Colors.green.shade300 : Colors.green.shade700;
      statusBg = isDark ? Colors.green.withValues(alpha: 0.15) : Colors.green.shade50;
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              color: statusColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Harvest & Yield Projection",
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, color: statusColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              statusTitle,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "OPTIMAL HARVEST DATE",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isReadyForHarvest ? "READY TO HARVEST" : DateFormat('MMM d, yyyy').format(predictedDate),
                              style: TextStyle(
                                color: isReadyForHarvest ? statusColor : colorScheme.onSurface,
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                              ),
                            ),
                            if (!isReadyForHarvest) ...[
                              const SizedBox(height: 2),
                              Text(
                                "in $remainingDays days",
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 50,
                        width: 1,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoRow("Target ABW", "${targetAbw.toStringAsFixed(0)} g", colorScheme),
                            const SizedBox(height: 4),
                            _buildInfoRow("Assumed Survival", "${(survivalRate * 100).toStringAsFixed(0)}%", colorScheme),
                            const SizedBox(height: 4),
                            _buildInfoRow("Estimated Yield", yieldDisplay, colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Growth Progress to Target",
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            "$progressPercentStr%",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: colorScheme.outlineVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Current: ${currentAbw.toStringAsFixed(1)}g",
                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            "Target: ${targetAbw.toStringAsFixed(0)}g",
                            style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ADG Trend Info banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isFallbackAdg ? Icons.info_outline_rounded : Icons.trending_up_rounded,
                          size: 14,
                          color: isFallbackAdg ? colorScheme.secondary : colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isFallbackAdg
                                ? "No recent growth rate (ADG). Projecting using default: ${adgTrend.toStringAsFixed(2)} g/day."
                                : "Growth Rate (ADG) Trend: ${adgTrend.toStringAsFixed(2)} g/day (based on last 3 samples).",
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Settings Toggle Button
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showProjectionSettings = !_showProjectionSettings;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showProjectionSettings ? "Hide Projection Settings" : "Configure Projection Settings",
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showProjectionSettings ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showProjectionSettings) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "PROJECTION SETTINGS",
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _customTargetAbw = null;
                              _customSurvivalRate = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Reset Defaults",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Target ABW Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Target Harvest Size",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${targetAbw.toStringAsFixed(0)} g",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: targetAbw,
                          min: 5.0,
                          max: 1200.0,
                          divisions: 239, // steps of 5g
                          label: "${targetAbw.round()}g",
                          onChanged: (val) {
                            setState(() {
                              _customTargetAbw = val;
                            });
                          },
                        ),
                      ],
                    ),
                    // Survival Rate Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Assumed Survival Rate",
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              "${(survivalRate * 100).toStringAsFixed(0)}%",
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Slider(
                          value: survivalRate,
                          min: 0.50,
                          max: 1.00,
                          divisions: 50, // steps of 1%
                          label: "${(survivalRate * 100).round()}%",
                          onChanged: (val) {
                            setState(() {
                              _customSurvivalRate = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return StreamBuilder<DocumentSnapshot<Pond>>(
      stream: _pondStream,
      builder: (context, pondSnapshot) {
        if (pondSnapshot.hasError) {
          return ErrorStateCard(
            description: "Error loading pond data: ${pondSnapshot.error}",
            onRetry: _refreshData,
          );
        }

        if (!pondSnapshot.hasData &&
            pondSnapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPlaceholder(message: "Loading pond data...");
        }

        final pond = pondSnapshot.data?.data();

        return FutureBuilder<List<GrowthMetrics>>(
          future: _growthMetricsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingPlaceholder(message: "Loading growth metrics...");
            }

            if (snapshot.hasError) {
              return ErrorStateCard(
                description: "Error: ${snapshot.error}",
                onRetry: _refreshData,
              );
            }

            final metrics = snapshot.data ?? [];

            if (metrics.isEmpty) {
              return RefreshIndicator(
                onRefresh: _refreshData,
                color: colorScheme.primary,
                backgroundColor: colorScheme.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 32.0,
                        ),
                        child: Center(
                          child: EmptyStateCard(
                            image: const Icon(Icons.query_stats_rounded),
                            title: "No growth records",
                            description:
                                "Tap 'Record Sampling' to log a measurement.",
                            scrollable: false,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refreshData,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  if (pond != null) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildAutoFeedCard(context, pond, metrics),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: _buildHarvestProjectionCard(context, pond, metrics),
                      ),
                    ),
                  ],
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final current = metrics[index];
                        final previous = (index < metrics.length - 1)
                            ? metrics[index + 1]
                            : null;
                        return StaggeredListItem(
                          index: index,
                          child: GrowthMetricCard(
                            current: current,
                            previous: previous,
                            canEdit: widget.canEdit,
                            onEdit: widget.onEdit,
                            onDelete: widget.onDelete,
                          ),
                        );
                      }, childCount: metrics.length),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100), // Spacing for FAB
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
