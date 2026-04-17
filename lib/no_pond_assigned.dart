import 'package:flutter/material.dart';

class NoPondAssignedWidget extends StatefulWidget {
  final Future<void> Function()? onRefresh;

  const NoPondAssignedWidget({super.key, this.onRefresh});

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
      child: Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.1),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      size: 48,
                      color: primaryColor.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Icon(
                      Icons.search_rounded,
                      size: 32,
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Waiting for Assignment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "You haven't been assigned to a pond yet. You can create one or ask your team leader to invite you.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Once assigned, you\'ll have access to:',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 16.0,
                      runSpacing: 12.0,
                      children: [
                        _buildRecordItem(primaryColor, 'Daily records'),
                        _buildRecordItem(primaryColor, 'Biweekly records'),
                        _buildRecordItem(primaryColor, 'Weekly records'),
                        _buildRecordItem(primaryColor, 'Team dashboard'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (widget.onRefresh != null)
                OutlinedButton.icon(
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  icon: _isRefreshing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: primaryColor,
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isRefreshing ? "Refreshing..." : "Refresh Status",
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryColor,
                    side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecordItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    );
  }
}
