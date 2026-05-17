import 'package:flutter/material.dart';

class PondStatusColors extends ThemeExtension<PondStatusColors> {
  final Color healthy;
  final Color warning;
  final Color critical;

  const PondStatusColors({
    required this.healthy,
    required this.warning,
    required this.critical,
  });

  @override
  ThemeExtension<PondStatusColors> copyWith({
    Color? healthy,
    Color? warning,
    Color? critical,
  }) {
    return PondStatusColors(
      healthy: healthy ?? this.healthy,
      warning: warning ?? this.warning,
      critical: critical ?? this.critical,
    );
  }

  @override
  ThemeExtension<PondStatusColors> lerp(
    ThemeExtension<PondStatusColors>? other,
    double t,
  ) {
    if (other is! PondStatusColors) {
      return this;
    }
    return PondStatusColors(
      healthy: Color.lerp(healthy, other.healthy, t) ?? healthy,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      critical: Color.lerp(critical, other.critical, t) ?? critical,
    );
  }
}

extension PondStatusColorsExtension on BuildContext {
  PondStatusColors get pondColors =>
      Theme.of(this).extension<PondStatusColors>()!;
}
