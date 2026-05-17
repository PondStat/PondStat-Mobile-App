import 'package:flutter/material.dart';

class AppMetrics extends ThemeExtension<AppMetrics> {
  // Padding
  final double paddingSmall;
  final double paddingMedium;
  final double paddingLarge;

  // Border Radius
  final double radiusSmall;
  final double radiusButton;
  final double radiusMedium;
  final double radiusLarge;
  final double radiusExtraLarge;

  // Icon Size
  final double iconSmall;
  final double iconMedium;
  final double iconLarge;

  const AppMetrics({
    required this.paddingSmall,
    required this.paddingMedium,
    required this.paddingLarge,
    required this.radiusSmall,
    required this.radiusButton,
    required this.radiusMedium,
    required this.radiusLarge,
    required this.radiusExtraLarge,
    required this.iconSmall,
    required this.iconMedium,
    required this.iconLarge,
  });

  // Standard phone metrics
  factory AppMetrics.standard() {
    return const AppMetrics(
      paddingSmall: 8.0,
      paddingMedium: 16.0,
      paddingLarge: 24.0,
      radiusSmall: 8.0,
      radiusButton: 12.0,
      radiusMedium: 16.0,
      radiusLarge: 20.0,
      radiusExtraLarge: 32.0,
      iconSmall: 16.0,
      iconMedium: 24.0,
      iconLarge: 32.0,
    );
  }

  // Example: Tablet metrics
  factory AppMetrics.tablet() {
    return const AppMetrics(
      paddingSmall: 12.0,
      paddingMedium: 24.0,
      paddingLarge: 32.0,
      radiusSmall: 12.0,
      radiusButton: 16.0,
      radiusMedium: 24.0,
      radiusLarge: 28.0,
      radiusExtraLarge: 40.0,
      iconSmall: 24.0,
      iconMedium: 32.0,
      iconLarge: 40.0,
    );
  }

  @override
  ThemeExtension<AppMetrics> copyWith({
    double? paddingSmall,
    double? paddingMedium,
    double? paddingLarge,
    double? radiusSmall,
    double? radiusButton,
    double? radiusMedium,
    double? radiusLarge,
    double? radiusExtraLarge,
    double? iconSmall,
    double? iconMedium,
    double? iconLarge,
  }) {
    return AppMetrics(
      paddingSmall: paddingSmall ?? this.paddingSmall,
      paddingMedium: paddingMedium ?? this.paddingMedium,
      paddingLarge: paddingLarge ?? this.paddingLarge,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      radiusButton: radiusButton ?? this.radiusButton,
      radiusMedium: radiusMedium ?? this.radiusMedium,
      radiusLarge: radiusLarge ?? this.radiusLarge,
      radiusExtraLarge: radiusExtraLarge ?? this.radiusExtraLarge,
      iconSmall: iconSmall ?? this.iconSmall,
      iconMedium: iconMedium ?? this.iconMedium,
      iconLarge: iconLarge ?? this.iconLarge,
    );
  }

  @override
  ThemeExtension<AppMetrics> lerp(
    ThemeExtension<AppMetrics>? other,
    double t,
  ) {
    if (other is! AppMetrics) {
      return this;
    }
    return AppMetrics(
      paddingSmall:
          lerpDouble(paddingSmall, other.paddingSmall, t) ?? paddingSmall,
      paddingMedium:
          lerpDouble(paddingMedium, other.paddingMedium, t) ?? paddingMedium,
      paddingLarge:
          lerpDouble(paddingLarge, other.paddingLarge, t) ?? paddingLarge,
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t) ?? radiusSmall,
      radiusButton:
          lerpDouble(radiusButton, other.radiusButton, t) ?? radiusButton,
      radiusMedium:
          lerpDouble(radiusMedium, other.radiusMedium, t) ?? radiusMedium,
      radiusLarge: lerpDouble(radiusLarge, other.radiusLarge, t) ?? radiusLarge,
      radiusExtraLarge:
          lerpDouble(radiusExtraLarge, other.radiusExtraLarge, t) ??
              radiusExtraLarge,
      iconSmall: lerpDouble(iconSmall, other.iconSmall, t) ?? iconSmall,
      iconMedium: lerpDouble(iconMedium, other.iconMedium, t) ?? iconMedium,
      iconLarge: lerpDouble(iconLarge, other.iconLarge, t) ?? iconLarge,
    );
  }

  double? lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}

extension AppMetricsExtension on BuildContext {
  AppMetrics get metrics => Theme.of(this).extension<AppMetrics>()!;
}
