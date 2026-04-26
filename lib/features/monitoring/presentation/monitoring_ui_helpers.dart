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
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.95)),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(SliverAppBarDelegate oldDelegate) => false;
}

class SlideGradientTransform extends GradientTransform {
  final double percent;
  const SlideGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (percent * 3 - 1.5),
      0.0,
      0.0,
    );
  }
}

extension GradientContainer on Container {
  Container applyGradient() {
    return Container(
      decoration: (decoration as BoxDecoration?)?.copyWith(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A74DA), Color(0xFF4FA0F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
