import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/features/monitoring/utils/growth_calculators.dart';

// Extracted validation functions from EditGrowthSheet for robust unit-testing
String? positiveNumberValidator(String? value) {
  if (value == null || value.isEmpty) return "Required";
  final number = double.tryParse(value);
  if (number == null) return "Invalid number";
  if (number <= 0) return "Must be greater than 0";
  return null;
}

String? nonNegativeNumberValidator(String? value) {
  if (value == null || value.isEmpty) return "Required";
  final number = double.tryParse(value);
  if (number == null) return "Invalid number";
  if (number < 0) return "Cannot be negative";
  return null;
}

String? adgValidator(String? value) {
  if (value == null || value.isEmpty) return "Required";
  final number = double.tryParse(value);
  if (number == null) return "Invalid number";
  return null;
}



void main() {
  group('Bacterial Replicates Calculations', () {
    test('should compute correct average for list of replicates', () {
      expect(GrowthCalculators.calculateBacterialAverage([10.0, 20.0, 30.0]), 20.0);
      expect(GrowthCalculators.calculateBacterialAverage([5.5, 6.5]), 6.0);
    });

    test('should compute correct CFU using dilution factors', () {
      expect(GrowthCalculators.calculateBacterialCfu(100.0, 100.0), 10000.0);
      expect(GrowthCalculators.calculateBacterialCfu(50.0, 1000.0), 50000.0);
    });
  });

  group('RecordGrowthSheet Calculations', () {
    group('ABW Calculation', () {
      test('should calculate ABW correctly with positive parameters', () {
        expect(GrowthCalculators.calculateABW(weight: 100.0, count: 10.0), 10.0);
      });

      test('should return null if weight or count is <= 0', () {
        expect(GrowthCalculators.calculateABW(weight: 0.0, count: 10.0), isNull);
        expect(GrowthCalculators.calculateABW(weight: -5.0, count: 10.0), isNull);
        expect(GrowthCalculators.calculateABW(weight: 100.0, count: 0.0), isNull);
        expect(GrowthCalculators.calculateABW(weight: 100.0, count: -1.0), isNull);
      });
    });

    group('ADG Calculation', () {
      test('should calculate positive ADG when weight increases', () {
        expect(GrowthCalculators.calculateADG(currentAbw: 15.0, previousAbw: 10.0, days: 5.0), 1.0);
      });

      test('should calculate negative ADG when weight decreases', () {
        expect(GrowthCalculators.calculateADG(currentAbw: 8.0, previousAbw: 10.0, days: 4.0), -0.5);
      });

      test('should return null if cur or prev weights are non-positive', () {
        expect(GrowthCalculators.calculateADG(currentAbw: 0.0, previousAbw: 10.0, days: 5.0), isNull);
        expect(GrowthCalculators.calculateADG(currentAbw: 15.0, previousAbw: -2.0, days: 5.0), isNull);
      });

      test('should return null if days is non-positive', () {
        expect(GrowthCalculators.calculateADG(currentAbw: 15.0, previousAbw: 10.0, days: 0.0), isNull);
        expect(GrowthCalculators.calculateADG(currentAbw: 15.0, previousAbw: 10.0, days: -1.0), isNull);
      });
    });

    group('DFR Calculation', () {
      test('should calculate DFR correctly under normal positive parameters', () {
        // 1000 fish * 90% survival * 10g abw * 5% feeding rate / 1000 = 0.45 kg/day
        expect(
          GrowthCalculators.calculateDFR(stocked: 1000.0, survivalRate: 90.0, abw: 10.0, feedingRate: 5.0),
          closeTo(0.45, 0.001),
        );
      });

      test('should return null if survival rate is outside 0-100%', () {
        expect(GrowthCalculators.calculateDFR(stocked: 1000.0, survivalRate: 101.0, abw: 10.0, feedingRate: 5.0), isNull);
        expect(GrowthCalculators.calculateDFR(stocked: 1000.0, survivalRate: -1.0, abw: 10.0, feedingRate: 5.0), isNull);
      });

      test('should return null if stocked quantity or abw is <= 0', () {
        expect(GrowthCalculators.calculateDFR(stocked: 0.0, survivalRate: 90.0, abw: 10.0, feedingRate: 5.0), isNull);
        expect(GrowthCalculators.calculateDFR(stocked: 1000.0, survivalRate: 90.0, abw: 0.0, feedingRate: 5.0), isNull);
      });

      test('should return null if feeding rate is outside 0-100%', () {
        expect(GrowthCalculators.calculateDFR(stocked: 1000.0, survivalRate: 90.0, abw: 10.0, feedingRate: 101.0), isNull);
        expect(GrowthCalculators.calculateDFR(stocked: 1000.0, survivalRate: 90.0, abw: 10.0, feedingRate: -0.5), isNull);
      });
    });

    group('FCR Calculation', () {
      test('should calculate FCR correctly under positive values', () {
        expect(GrowthCalculators.calculateFCR(feedGiven: 120.0, weightGained: 100.0), 1.2);
      });

      test('should return null if feed or weight gained is <= 0', () {
        expect(GrowthCalculators.calculateFCR(feedGiven: 0.0, weightGained: 100.0), isNull);
        expect(GrowthCalculators.calculateFCR(feedGiven: 120.0, weightGained: 0.0), isNull);
        expect(GrowthCalculators.calculateFCR(feedGiven: -10.0, weightGained: 100.0), isNull);
        expect(GrowthCalculators.calculateFCR(feedGiven: 120.0, weightGained: -5.0), isNull);
      });
    });
  });

  group('EditGrowthSheet Validators', () {
    group('positiveNumberValidator (ABW & FCR)', () {
      test('should return error for empty or null', () {
        expect(positiveNumberValidator(null), 'Required');
        expect(positiveNumberValidator(''), 'Required');
      });

      test('should return error for invalid numbers', () {
        expect(positiveNumberValidator('abc'), 'Invalid number');
        expect(positiveNumberValidator('12.3a'), 'Invalid number');
      });

      test('should return error for negative or zero', () {
        expect(positiveNumberValidator('0'), 'Must be greater than 0');
        expect(positiveNumberValidator('-1.5'), 'Must be greater than 0');
      });

      test('should return null for positive numbers', () {
        expect(positiveNumberValidator('10.5'), isNull);
        expect(positiveNumberValidator('0.001'), isNull);
      });
    });

    group('nonNegativeNumberValidator (DFR)', () {
      test('should return error for empty or null', () {
        expect(nonNegativeNumberValidator(null), 'Required');
        expect(nonNegativeNumberValidator(''), 'Required');
      });

      test('should return error for invalid numbers', () {
        expect(nonNegativeNumberValidator('abc'), 'Invalid number');
      });

      test('should return error for negative numbers', () {
        expect(nonNegativeNumberValidator('-0.1'), 'Cannot be negative');
      });

      test('should return null for zero or positive numbers', () {
        expect(nonNegativeNumberValidator('0'), isNull);
        expect(nonNegativeNumberValidator('120'), isNull);
      });
    });

    group('adgValidator (ADG)', () {
      test('should return error for empty or null', () {
        expect(adgValidator(null), 'Required');
        expect(adgValidator(''), 'Required');
      });

      test('should return error for invalid numbers', () {
        expect(adgValidator('abc'), 'Invalid number');
      });

      test('should return null for any valid number (positive, negative, zero)', () {
        expect(adgValidator('1.2'), isNull);
        expect(adgValidator('-0.5'), isNull);
        expect(adgValidator('0'), isNull);
      });
    });
  });
}
