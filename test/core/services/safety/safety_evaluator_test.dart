import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/services/safety/safety_evaluator.dart';
import 'package:pondstat/core/services/safety/alert_types.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

import 'package:flutter/material.dart';

void main() {
  group('SafetyEvaluator', () {
    late SafetyEvaluator evaluator;

    setUp(() {
      evaluator = SafetyEvaluator();
    });

    final testParameter = ParameterItem(
      label: 'pH',
      unit: '',
      icon: Icons.water_drop,
      category: ParameterCategory.chemical,
      absoluteMin: 6.0,
      absoluteMax: 9.0,
      optimalMin: 7.0,
      optimalMax: 8.0,
    );

    test('returns null when value is within optimal bounds', () {
      final result = evaluator.evaluate(testParameter, 7.5);
      expect(result, isNull);
    });

    test('returns Warning below when value is below optimal but above absolute', () {
      final result = evaluator.evaluate(testParameter, 6.5);
      expect(result?.tier, AlertTier.warning);
      expect(result?.direction, AlertDirection.below);
    });

    test('returns Warning above when value is above optimal but below absolute', () {
      final result = evaluator.evaluate(testParameter, 8.5);
      expect(result?.tier, AlertTier.warning);
      expect(result?.direction, AlertDirection.above);
    });

    test('returns Critical below when value is below absolute', () {
      final result = evaluator.evaluate(testParameter, 5.5);
      expect(result?.tier, AlertTier.critical);
      expect(result?.direction, AlertDirection.below);
    });

    test('returns Critical above when value is above absolute', () {
      final result = evaluator.evaluate(testParameter, 9.5);
      expect(result?.tier, AlertTier.critical);
      expect(result?.direction, AlertDirection.above);
    });

    test('ignores missing bounds gracefully', () {
      final paramNoMin = ParameterItem(
        label: 'Weight',
        unit: 'g',
        icon: Icons.monitor_weight,
        category: ParameterCategory.growth,
        absoluteMax: 100.0,
      );

      expect(evaluator.evaluate(paramNoMin, 10.0), isNull); // No lower bound, 10 is fine
      expect(evaluator.evaluate(paramNoMin, 110.0)?.tier, AlertTier.critical); // Exceeds upper
    });
  });
}
