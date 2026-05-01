import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MonitoringHeader extends StatelessWidget {
  final String pondId;
  final String pondName;
  final VoidCallback onBackTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onProfileTap;
  final Color primaryBlue;
  final Color secondaryBlue;

  const MonitoringHeader({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.onBackTap,
    required this.onHistoryTap,
    required this.onProfileTap,
    required this.primaryBlue,
    required this.secondaryBlue,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final surfaceContainer = isDark
        ? Theme.of(context).colorScheme.surfaceContainerHighest
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: onSurface),
            onPressed: onBackTap,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONITORING",
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  pondName,
                  style: TextStyle(
                    color: onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildCircleIconButton(
            context: context,
            icon: Icons.history_rounded,
            onPressed: onHistoryTap,
            tooltip: 'History',
            surfaceContainer: surfaceContainer,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onProfileTap,
            child: _buildCircleContainer(
              surfaceContainer: surfaceContainer,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark
                      ? Colors.white12
                      : Colors.grey.shade100,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName![0].toUpperCase()
                              : 'U',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleIconButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color surfaceContainer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildCircleContainer(
      surfaceContainer: surfaceContainer,
      child: IconButton(
        icon: Icon(
          icon,
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildCircleContainer({
    required Widget child,
    required Color surfaceContainer,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
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
