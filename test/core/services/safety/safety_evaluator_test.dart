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

    group('Species-specific weekly and biweekly parameters', () {
      test('Dissolved Oxygen thresholds differ for Shrimp vs Tilapia', () {
        final doShrimp = MonitoringParameters.getParameterByLabel('Dissolved Oxygen', 'shrimp')!;
        final doTilapia = MonitoringParameters.getParameterByLabel('Dissolved Oxygen', 'tilapia')!;

        // 4.5 mg/L DO is warning-low for shrimp (opt min 5.0)
        final resultShrimp = evaluator.evaluate(doShrimp, 4.5);
        expect(resultShrimp?.tier, AlertTier.warning);
        expect(resultShrimp?.direction, AlertDirection.below);

        // 4.5 mg/L DO is optimal for tilapia (opt min 4.0)
        final resultTilapia = evaluator.evaluate(doTilapia, 4.5);
        expect(resultTilapia, isNull);
      });

      test('Calcium thresholds differ for Shrimp vs Tilapia', () {
        final caShrimp = MonitoringParameters.getParameterByLabel('Calcium', 'shrimp')!;
        final caTilapia = MonitoringParameters.getParameterByLabel('Calcium', 'tilapia')!;

        // 100 mg/L Calcium is warning-low for shrimp (opt min 120)
        final resultShrimp = evaluator.evaluate(caShrimp, 100.0);
        expect(resultShrimp?.tier, AlertTier.warning);
        expect(resultShrimp?.direction, AlertDirection.below);

        // 100 mg/L Calcium is optimal for tilapia (opt range 40-120)
        final resultTilapia = evaluator.evaluate(caTilapia, 100.0);
        expect(resultTilapia, isNull);
      });

      test('Phytoplankton thresholds differ for Shrimp vs Tilapia', () {
        final phytoShrimp = MonitoringParameters.getParameterByLabel('Phytoplankton', 'shrimp')!;
        final phytoTilapia = MonitoringParameters.getParameterByLabel('Phytoplankton', 'tilapia')!;

        // 15,000 cells/mL is warning-low for shrimp (opt min 20,000)
        final resultShrimp = evaluator.evaluate(phytoShrimp, 15000.0);
        expect(resultShrimp?.tier, AlertTier.warning);
        expect(resultShrimp?.direction, AlertDirection.below);

        // 15,000 cells/mL is optimal for tilapia (opt range 10,000-80,000)
        final resultTilapia = evaluator.evaluate(phytoTilapia, 15000.0);
        expect(resultTilapia, isNull);
      });

      test('Bacterial analysis parameters do not trigger warnings', () {
        final avgYellow = MonitoringParameters.getParameterByLabel('Test 10-1 (Average yellow colonies)', 'shrimp')!;
        final cfuGreen = MonitoringParameters.getParameterByLabel('Test green 10-2 (CFU/ml)', 'tilapia')!;

        expect(evaluator.evaluate(avgYellow, 500.0), isNull);
        expect(evaluator.evaluate(cfuGreen, 25000.0), isNull);
      });
    });
  });
}
