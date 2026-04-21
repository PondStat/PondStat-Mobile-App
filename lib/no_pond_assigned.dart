import 'package:flutter/material.dart';

class NoPondAssignedWidget extends StatefulWidget {
  final Future<void> Function()? onRefresh;
  final VoidCallback? onCreatePond;

  const NoPondAssignedWidget({super.key, this.onRefresh, this.onCreatePond});

  @override
  State<NoPondAssignedWidget> createState() => _NoPondAssignedWidgetState();
}

class _NoPondAssignedWidgetState extends State<NoPondAssignedWidget> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null || _isRefreshing) return;

    setState(() => _isRefreshing = true);

    try {
      await widget.onRefresh!();
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: primaryColor,
      backgroundColor: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: 48,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Welcome to Fish 125 Labs',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You haven't been assigned to a pond yet. Create your first pond to begin your aquaculture practice, or request an invitation from your team leader.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.blueGrey.shade700,
                  fontSize: 16,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.dashboard_customize_rounded, color: primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Once assigned, you\'ll unlock:',
                          style: TextStyle(
                            color: Colors.blueGrey.shade900,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildFeatureItem(Icons.water_drop_rounded, 'Pond Parameters', Colors.blue),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.trending_up_rounded, 'Growth Analytics', Colors.green),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.bar_chart_rounded, 'Graphs for Trends', Colors.purple),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.receipt_long_rounded, 'Expense Tracker', Colors.teal),
                    const SizedBox(height: 12),
                    _buildFeatureItem(Icons.event_note_rounded, 'Scheduler Manager', Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (widget.onRefresh != null)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isRefreshing ? null : _handleRefresh,
                    icon: _isRefreshing
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: primaryColor,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 22),
                    label: Text(
                      _isRefreshing ? "Refreshing..." : "Refresh Status",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.blueGrey.shade800,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
