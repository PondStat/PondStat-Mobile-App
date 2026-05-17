import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/theme/app_metrics.dart';
import 'package:pondstat/core/theme/pond_status_colors.dart';

void main() {
  group('AppMetrics', () {
    test('lerp works correctly', () {
      final a = AppMetrics.standard();
      final b = AppMetrics.tablet();

      final lerped = a.lerp(b, 0.5) as AppMetrics;

      expect(lerped.paddingLarge, (a.paddingLarge + b.paddingLarge) / 2);
      expect(lerped.iconSmall, (a.iconSmall + b.iconSmall) / 2);
    });

    test('lerp returns this when other is null or wrong type', () {
      final a = AppMetrics.standard();
      expect(a.lerp(null, 0.5), a);
    });

    test('copyWith works correctly', () {
      final a = AppMetrics.standard();
      final copied = a.copyWith(paddingLarge: 100.0) as AppMetrics;

      expect(copied.paddingLarge, 100.0);
      expect(copied.iconSmall, a.iconSmall); // Unchanged
    });
  });

  group('PondStatusColors', () {
    test('lerp works correctly', () {
      const a = PondStatusColors(
        healthy: Colors.green,
        warning: Colors.orange,
        critical: Colors.red,
      );
      const b = PondStatusColors(
        healthy: Colors.lightGreen,
        warning: Colors.deepOrange,
        critical: Colors.redAccent,
      );

      final lerped = a.lerp(b, 0.5) as PondStatusColors;

      expect(lerped.healthy, Color.lerp(Colors.green, Colors.lightGreen, 0.5));
    });

    test('copyWith works correctly', () {
      const a = PondStatusColors(
        healthy: Colors.green,
        warning: Colors.orange,
        critical: Colors.red,
      );

      final copied = a.copyWith(healthy: Colors.blue) as PondStatusColors;

      expect(copied.healthy, Colors.blue);
      expect(copied.warning, Colors.orange);
    });
  });
}
