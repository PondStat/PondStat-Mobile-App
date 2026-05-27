import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pondstat/features/monitoring/presentation/widgets/custom_showcase.dart';
import 'package:pondstat/core/utils/responsive_helper.dart';

import 'package:pondstat/features/auth/data/auth_repository.dart';

class MonitoringHeader extends ConsumerWidget {
  final String pondId;
  final String pondName;
  final String species;
  final VoidCallback onBackTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onChatTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onHelpTap;
  final GlobalKey? profileKey;
  final GlobalKey? historyKey;
  final GlobalKey? chatKey;
  final GlobalKey? helpKey;

  const MonitoringHeader({
    super.key,
    required this.pondId,
    required this.pondName,
    required this.species,
    required this.onBackTap,
    required this.onHistoryTap,
    required this.onChatTap,
    required this.onProfileTap,
    this.onHelpTap,
    this.profileKey,
    this.historyKey,
    this.chatKey,
    this.helpKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userChangesProvider);
    final user = userAsync.value ?? FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = colorScheme.onSurface;
    final surfaceContainer = isDark
        ? colorScheme.surfaceContainerHighest
        : Colors.white;

    final bool isWide = ResponsiveHelper.isWide(context);

    // Dynamic responsive sizing
    final double iconSize = isWide ? 44 : 36;
    final double actionBtnSize = isWide ? 40 : 34;
    final double actionIconSize = isWide ? 22 : 18;
    final double backBtnSize = isWide ? 40 : 32;
    final double backIconSize = isWide ? 24 : 20;
    final double spaceBetween = isWide ? 8 : 4;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 20.0 : 12.0, vertical: 12),
      child: Row(
        children: [
          // Hero species icon — matches pond-icon-{pondId} tag in PondListCard
          Hero(
            tag: 'pond-icon-$pondId',
            child: Container(
              height: iconSize,
              width: iconSize,
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
                  size: isWide ? 20 : 16,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: onSurface),
            onPressed: onBackTap,
            tooltip: 'Back',
            iconSize: backIconSize,
            constraints: BoxConstraints(minWidth: backBtnSize, minHeight: backBtnSize),
            padding: EdgeInsets.zero,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "MONITORING",
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontSize: isWide ? 10 : 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pondName,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: isWide ? 22 : 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onHelpTap != null) ...[
            CustomShowcase(
              showcaseKey: helpKey ?? GlobalKey(),
              scope: 'pond_monitoring',
              title: "Tour Guide",
              description: "Tap this at any time to re-run the tutorial tour for the active tab.",
              targetShapeBorder: const CircleBorder(),
              child: _buildCircleIconButton(
                context: context,
                icon: Icons.help_outline_rounded,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onHelpTap!();
                },
                tooltip: 'Help & Tour',
                surfaceContainer: surfaceContainer,
                size: actionBtnSize,
                iconSize: actionIconSize,
              ),
            ),
            SizedBox(width: spaceBetween),
          ],
          CustomShowcase(
            showcaseKey: historyKey ?? GlobalKey(),
            scope: 'pond_monitoring',
            title: "View Edit History & Log Audit Trails",
            description: "Audit any parameter adjustments, see who modified what values, and track historical logs.",
            targetShapeBorder: const CircleBorder(),
            child: _buildCircleIconButton(
              context: context,
              icon: Icons.receipt_long_rounded,
              onPressed: () {
                HapticFeedback.selectionClick();
                onHistoryTap();
              },
              tooltip: 'Log History',
              surfaceContainer: surfaceContainer,
              size: actionBtnSize,
              iconSize: actionIconSize,
            ),
          ),
          SizedBox(width: spaceBetween),
          CustomShowcase(
            showcaseKey: chatKey ?? GlobalKey(),
            scope: 'pond_monitoring',
            title: "Collaborative Chat & Notes",
            description: "Use this chat interface to leave remarks, upload photos, and chat in real-time with other collaborators.",
            targetShapeBorder: const CircleBorder(),
            child: _buildCircleIconButton(
              context: context,
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {
                HapticFeedback.selectionClick();
                onChatTap();
              },
              tooltip: 'Chat & Notes',
              surfaceContainer: surfaceContainer,
              size: actionBtnSize,
              iconSize: actionIconSize,
            ),
          ),
          SizedBox(width: spaceBetween),
          CustomShowcase(
            showcaseKey: profileKey ?? GlobalKey(),
            scope: 'pond_monitoring',
            title: "Manage Pond Collaborators",
            description: "Invite and manage farm hands, editors, or other viewers to help you monitor this pond's parameters! Tap your profile icon to configure.",
            targetShapeBorder: const CircleBorder(),
            child: Material(
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
                      radius: isWide ? 18 : 15,
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
    required double size,
    required double iconSize,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildCircleContainer(
      context: context,
      surfaceContainer: surfaceContainer,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(
          icon: Icon(
            icon,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
          iconSize: iconSize,
          padding: EdgeInsets.zero,
          tooltip: tooltip,
          onPressed: onPressed,
        ),
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
