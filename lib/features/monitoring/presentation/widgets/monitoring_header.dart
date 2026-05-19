import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MonitoringHeader extends StatelessWidget {
  final String pondId;
  final String pondName;
  final String species;
  final VoidCallback onBackTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onProfileTap;

  const MonitoringHeader({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.onBackTap,
    required this.onHistoryTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = colorScheme.onSurface;
    final surfaceContainer = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
      child: Row(
        children: [
          // Hero species icon — matches pond-icon-{pondId} tag in PondListCard
          Hero(
            tag: 'pond-icon-$pondId',
            child: Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.secondary, colorScheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: isDark ? 0.4 : 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: FaIcon(
                  _getSpeciesIcon(species),
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: onSurface),
            onPressed: onBackTap,
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONITORING",
                  style: TextStyle(
                    color: colorScheme.primary,
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
            icon: Icons.receipt_long_rounded,
            onPressed: () {
              HapticFeedback.selectionClick();
              onHistoryTap();
            },
            tooltip: 'Log History',
            surfaceContainer: surfaceContainer,
          ),
          const SizedBox(width: 8),
          Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onProfileTap();
              },
              customBorder: const CircleBorder(),
              child: _buildCircleContainer(
                context: context,
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
                    onBackgroundImageError: user?.photoURL != null
                        ? (exception, stackTrace) {}
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          )
                        : null,
                  ),
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
      context: context,
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
    required BuildContext context,
    required Widget child,
    required Color surfaceContainer,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: surfaceContainer,
        shape: BoxShape.circle,
        boxShadow: isDark
            ? null
            : [
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
  IconData _getSpeciesIcon(String species) {
    final lower = species.toLowerCase();
    if (lower.contains('tilapia') || lower.contains('fish')) {
      return FontAwesomeIcons.fish;
    }
    if (lower.contains('shrimp') ||
        lower.contains('prawn') ||
        lower.contains('vannamei')) {
      return FontAwesomeIcons.shrimp;
    }
    return FontAwesomeIcons.droplet;
  }
}
