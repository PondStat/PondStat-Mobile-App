import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'growth_data_service.dart';

class GrowthTab extends StatefulWidget {
  final String pondId;

  const GrowthTab({super.key, required this.pondId});

  @override
  State<GrowthTab> createState() => _GrowthTabState();
}

class _GrowthTabState extends State<GrowthTab> {
  final Color primaryIndigo = Colors.indigo;
  final Color textDark = const Color(0xFF1E293B);
  final Color textMuted = const Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GrowthMetrics>>(
      future: GrowthDataService.calculateGrowthMetrics(widget.pondId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final metrics = snapshot.data ?? [];

        if (metrics.isEmpty) {
          return _buildEmptyState();
        }

        final latest = metrics.first;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          children: [
            _buildSummaryGrid(latest),
            const SizedBox(height: 24),
            _buildSectionHeader("Growth History"),
            const SizedBox(height: 12),
            ...metrics.map((m) => _buildGrowthCard(m)),
            const SizedBox(height: 100), // Spacing for FAB
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: textMuted,
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSummaryGrid(GrowthMetrics latest) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        SummaryCard(
          label: "Current ABW",
          value: "${latest.abw.toStringAsFixed(1)}g",
          icon: Icons.monitor_weight_rounded,
          color: Colors.blue,
        ),
        SummaryCard(
          label: "Latest ADG",
          value: "${latest.adg.toStringAsFixed(2)}g",
          icon: Icons.trending_up_rounded,
          color: Colors.green,
        ),
        SummaryCard(
          label: "Current FCR",
          value: latest.fcr.toStringAsFixed(2),
          icon: Icons.assignment_rounded,
          color: Colors.orange,
        ),
        SummaryCard(
          label: "Current DFR",
          value: latest.dfr.toStringAsFixed(2),
          icon: Icons.set_meal_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildGrowthCard(GrowthMetrics m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(m.date),
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "ABW: ${m.abw}g",
                  style: TextStyle(
                    color: primaryIndigo,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniMetric(
                "ADG",
                "${m.adg.toStringAsFixed(2)}g",
                Colors.green,
              ),
              _buildMiniMetric("FCR", m.fcr.toStringAsFixed(2), Colors.orange),
              _buildMiniMetric(
                "DFR",
                m.dfr.toStringAsFixed(2),
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.query_stats_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No Growth Records Yet",
            style: TextStyle(
              color: textDark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Start recording weight and fish count weekly to see performance metrics here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MiniMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
