import 'package:flutter/material.dart';
import 'package:pondstat/core/theme/app_metrics.dart';

enum _EmptyStateMode { standard, primary, compact }

class EmptyStateCard extends StatelessWidget {
  final Widget image;
  final String title;
  final String description;
  final Widget? action;
  final _EmptyStateMode _mode;
  final bool scrollable;

  const EmptyStateCard({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    this.action,
    this.scrollable = true,
  }) : _mode = _EmptyStateMode.standard;

  const EmptyStateCard.primary({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    this.action,
    this.scrollable = true,
  }) : _mode = _EmptyStateMode.primary;

  const EmptyStateCard.compact({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    this.action,
    this.scrollable = true,
  }) : _mode = _EmptyStateMode.compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final metrics = context.metrics;

    final bool isCompact = _mode == _EmptyStateMode.compact;
    final bool isPrimary = _mode == _EmptyStateMode.primary;

    final double cardPadding = isCompact ? metrics.paddingMedium : (isPrimary ? metrics.paddingLarge * 1.5 : metrics.paddingLarge);
    final double iconContainerPadding = isCompact ? metrics.paddingMedium : 28.0;
    final double spaceBetweenText = isCompact ? metrics.paddingSmall : (metrics.paddingMedium * 0.75);
    final double spaceAboveAction = isCompact ? metrics.paddingLarge : (isPrimary ? 40.0 : metrics.paddingLarge);

    Widget content = Center(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Semantics(
          label: '$title. $description',
          container: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(iconContainerPadding),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
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
                      child: IconTheme(
                        data: IconThemeData(
                          size: isCompact ? metrics.iconLarge : 64.0,
                          color: isPrimary
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.primary,
                        ),
                        child: image,
                      ),
                    ),
                    SizedBox(height: isCompact ? 24 : 32),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: isCompact 
                          ? theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            )
                          : theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
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
                  ],
                ),
              ),
              if (action != null) ...[
                SizedBox(height: spaceAboveAction),
                action!,
              ],
            ],
          ),
        ),
      ),
    );

    if (!scrollable) {
      return content;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight == double.infinity) {
          return content;
        }

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
