import 'package:flutter/material.dart';
import 'sync_status_icon.dart';

class MonitoringHeader extends StatelessWidget {
  final String pondId;
  final VoidCallback onBackTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onProfileTap;
  final Color primaryBlue;
  final Color secondaryBlue;

  const MonitoringHeader({
    super.key,
    required this.pondId,
    required this.onBackTap,
    required this.onHistoryTap,
    required this.onProfileTap,
    required this.primaryBlue,
    required this.secondaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20.0,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFF1E293B),
            ),
            onPressed: onBackTap,
          ),
          Hero(
            tag: 'pond-icon-$pondId',
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [secondaryBlue, primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "PondStat",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                SyncStatusIcon(),
              ],
            ),
          ),
          _buildCircleIconButton(
            icon: Icons.history_rounded,
            onPressed: onHistoryTap,
            tooltip: 'Edit History',
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: _buildCircleContainer(
              child: const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF64748B),
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return _buildCircleContainer(
      child: IconButton(
        icon: Icon(icon, color: const Color(0xFF64748B)),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCircleContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
