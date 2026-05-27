import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;

  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.8),
            boxShadow: overlapsContent
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: _tabBar,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) => false;
}

BoxDecoration getPrimaryGradient(BuildContext context) {
  final theme = Theme.of(context);
  return BoxDecoration(
    gradient: LinearGradient(
      colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );
}
