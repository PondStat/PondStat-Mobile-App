import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class CustomShowcase extends StatelessWidget {
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final ShapeBorder? targetShapeBorder;
  final BorderRadius? targetBorderRadius;
  final EdgeInsets? tooltipPadding;

  const CustomShowcase({
    super.key,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.targetShapeBorder,
    this.targetBorderRadius,
    this.tooltipPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Showcase(
      key: showcaseKey,
      title: title,
      description: description,
      tooltipBackgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      textColor: isDark ? Colors.white : Colors.black87,
      titleTextStyle: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: colorScheme.primary,
        fontFamily: 'Inter',
        letterSpacing: -0.3,
      ),
      descTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white70 : Colors.black54,
        fontFamily: 'Inter',
        height: 1.4,
      ),
      targetShapeBorder: targetShapeBorder ?? const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      targetBorderRadius: targetBorderRadius,
      tooltipPadding: tooltipPadding ?? const EdgeInsets.all(16),
      overlayColor: Colors.black,
      overlayOpacity: 0.6,
      movingAnimationDuration: const Duration(milliseconds: 2000),
      child: child,
    );
  }
}
