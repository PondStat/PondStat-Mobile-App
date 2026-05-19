import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/features/monitoring/presentation/monitoring_parameters.dart';

void main() {
  group('ParameterItem Equality and HashCode', () {
    test('Should be equal when label and unit are identical', () {
      const item1 = ParameterItem(
        label: 'Dissolved Oxygen',
        unit: 'mg/L',
        icon: Icons.air_rounded,
        category: ParameterCategory.chemical,
      );

      const item2 = ParameterItem(
        label: 'Dissolved Oxygen',
        unit: 'mg/L',
        icon: Icons.water_drop_rounded, // Different icon
        category: ParameterCategory.physical, // Different category
      );

      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('Should not be equal when labels are different', () {
      const item1 = ParameterItem(
        label: 'Dissolved Oxygen',
        unit: 'mg/L',
        icon: Icons.air_rounded,
        category: ParameterCategory.chemical,
      );

      const item2 = ParameterItem(
        label: 'Ammonia',
        unit: 'mg/L',
        icon: Icons.air_rounded,
        category: ParameterCategory.chemical,
      );

      expect(item1, isNot(equals(item2)));
    });

    test('Should not be equal when units are different', () {
      const item1 = ParameterItem(
        label: 'Temperature',
        unit: '°C',
        icon: Icons.thermostat_rounded,
        category: ParameterCategory.physical,
      );

      const item2 = ParameterItem(
        label: 'Temperature',
        unit: '°F',
        icon: Icons.thermostat_rounded,
        category: ParameterCategory.physical,
      );

      expect(item1, isNot(equals(item2)));
    });
  });
}
