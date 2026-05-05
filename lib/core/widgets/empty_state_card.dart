import 'package:flutter/material.dart';

class EmptyStateCard extends StatelessWidget {
  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String description;
  final Widget? action;
  final bool isPrimary;
  final bool isCompact;

  const EmptyStateCard({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    required this.description,
    this.action,
    this.isPrimary = false,
    this.isCompact = false,
  }) : assert(
         icon != null || illustration != null,
         'Either icon or illustration must be provided.',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final double cardPadding = isCompact ? 16.0 : (isPrimary ? 48.0 : 32.0);
    final double iconContainerPadding = isCompact ? 16.0 : 28.0;
    final double iconSize = isCompact ? 48.0 : 64.0;
    final double titleSize = isCompact ? 18.0 : 22.0;
    final double spaceBetweenText = isCompact ? 8.0 : 12.0;
    final double spaceAboveAction = isCompact
        ? 24.0
        : (isPrimary ? 40.0 : 32.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(iconContainerPadding),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.15 : 0.08,
                    ),
                    blurRadius: isCompact ? 16 : 32,
                    offset: Offset(0, isCompact ? 8 : 16),
                  ),
                ],
              ),
              child:
                  illustration ??
                  Icon(
                    icon,
                    size: iconSize,
                    color: isDark
                        ? colorScheme.primary.withValues(alpha: 0.5)
                        : colorScheme.primary.withValues(alpha: 0.25),
                  ),
            ),
            SizedBox(height: isCompact ? 24 : 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
                fontSize: titleSize,
              ),
            ),
            SizedBox(height: spaceBetweenText),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              SizedBox(height: spaceAboveAction),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
