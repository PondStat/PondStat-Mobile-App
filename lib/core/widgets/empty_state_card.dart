import 'package:flutter/material.dart';

enum EmptyStateStyle { standard, primary, compact }

class EmptyStateCard extends StatelessWidget {
  final IconData? icon;
  final Widget? illustration;
  final String title;
  final String description;
  final Widget? action;
  final EmptyStateStyle style;

  const EmptyStateCard({
    super.key,
    this.icon,
    this.illustration,
    required this.title,
    required this.description,
    this.action,
    this.style = EmptyStateStyle.standard,
  }) : assert(
         icon != null || illustration != null,
         'Either icon or illustration must be provided.',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bool isCompact = style == EmptyStateStyle.compact;
    final bool isPrimary = style == EmptyStateStyle.primary;

    final double cardPadding = isCompact ? 16.0 : (isPrimary ? 48.0 : 32.0);
    final double iconContainerPadding = isCompact ? 16.0 : 28.0;
    final double iconSize = isCompact ? 48.0 : 64.0;
    final double titleSize = isCompact ? 18.0 : 22.0;
    final double spaceBetweenText = isCompact ? 8.0 : 12.0;
    final double spaceAboveAction = isCompact
        ? 24.0
        : (isPrimary ? 40.0 : 32.0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: Semantics(
                    label: '$title. $description',
                    container: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExcludeSemantics(
                          child: Column(
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
                                child:
                                    illustration ??
                                    Icon(
                                      icon,
                                      size: iconSize,
                                      color: isPrimary
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.primary,
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
              ),
            ),
          );
        },
      ),
    );
  }
}
