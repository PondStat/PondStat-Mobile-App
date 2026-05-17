import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/services/safety/alert_formatter.dart';
import 'package:pondstat/core/services/safety/safety_evaluator.dart';
import 'package:pondstat/core/services/safety/alert_types.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

import 'package:flutter/material.dart';

void main() {
  group('AlertFormatter', () {
    late AlertFormatter formatter;

    setUp(() {
      formatter = AlertFormatter();
    });

    final testParameter = ParameterItem(
      label: 'DO',
      unit: 'mg/L',
      icon: Icons.water_drop,
      category: ParameterCategory.chemical,
      absoluteMin: 3.0,
      optimalMin: 5.0,
    );

    test('formats a critical alert without magic defaults', () {
      final evaluation = SafetyEvaluation(tier: AlertTier.critical, direction: AlertDirection.below);
      
      final payload = formatter.format(
        evaluation: evaluation,
        parameter: testParameter,
        value: 2.0,
        pondId: 'p1',
        pondName: 'Pond A',
      );

      expect(payload.title, '🚨 CRITICAL: DO - Pond A');
      expect(payload.body, contains('DO is low: 2.0 mg/L'));
      expect(payload.body, contains('Must be above 3.0 mg/L'));
      expect(payload.body, isNot(contains('0.0'))); // Should NOT fallback to 0
      expect(payload.routePayload, '/monitoring?pondId=p1&parameter=DO');
    });

    test('formats a warning alert correctly', () {
      final evaluation = SafetyEvaluation(tier: AlertTier.warning, direction: AlertDirection.below);
      
      final payload = formatter.format(
        evaluation: evaluation,
        parameter: testParameter,
        value: 4.5,
        pondId: 'p2',
        pondName: 'Pond B',
      );

      expect(payload.title, '⚠️ Warning: DO - Pond B');
      expect(payload.body, contains('Should be above 5.0 mg/L'));
    });
  });
}
