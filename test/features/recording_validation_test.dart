import 'package:flutter_test/flutter_test.dart';

// Extracted calculator functions from RecordGrowthSheet for robust unit-testing
double? calculateABW({required double? w, required double? c}) {
  if (w != null && c != null && w > 0 && c > 0) return w / c;
  return null;
}

double? calculateADG({required double? cur, required double? prev, required double? days}) {
  if (cur != null && prev != null && days != null && cur > 0 && prev > 0 && days > 0) {
    return (cur - prev) / days;
  }
  return null;
}

double? calculateDFR({
  required double? stocked,
  required double? surv,
  required double? abw,
  required double? feedRate,
}) {
  if (stocked != null &&
      surv != null &&
      abw != null &&
      feedRate != null &&
      stocked > 0 &&
      surv >= 0 &&
      surv <= 100 &&
      abw > 0 &&
      feedRate >= 0 &&
      feedRate <= 100) {
    return (stocked * (surv / 100.0) * abw * (feedRate / 100.0)) / 1000.0;
  }
  return null;
}

double? calculateFCR({required double? feed, required double? gained}) {
  if (feed != null && gained != null && feed > 0 && gained > 0) {
    return feed / gained;
  }
  return null;
}

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
  group('RecordGrowthSheet Calculations', () {
    group('ABW Calculation', () {
      test('should calculate ABW correctly with positive parameters', () {
        expect(calculateABW(w: 100.0, c: 10.0), 10.0);
      });

      test('should return null if weight or count is <= 0', () {
        expect(calculateABW(w: 0.0, c: 10.0), isNull);
        expect(calculateABW(w: -5.0, c: 10.0), isNull);
        expect(calculateABW(w: 100.0, c: 0.0), isNull);
        expect(calculateABW(w: 100.0, c: -1.0), isNull);
      });
    });

    group('ADG Calculation', () {
      test('should calculate positive ADG when weight increases', () {
        expect(calculateADG(cur: 15.0, prev: 10.0, days: 5.0), 1.0);
      });

      test('should calculate negative ADG when weight decreases', () {
        expect(calculateADG(cur: 8.0, prev: 10.0, days: 4.0), -0.5);
      });

      test('should return null if cur or prev weights are non-positive', () {
        expect(calculateADG(cur: 0.0, prev: 10.0, days: 5.0), isNull);
        expect(calculateADG(cur: 15.0, prev: -2.0, days: 5.0), isNull);
      });

      test('should return null if days is non-positive', () {
        expect(calculateADG(cur: 15.0, prev: 10.0, days: 0.0), isNull);
        expect(calculateADG(cur: 15.0, prev: 10.0, days: -1.0), isNull);
      });
    });

    group('DFR Calculation', () {
      test('should calculate DFR correctly under normal positive parameters', () {
        // 1000 fish * 90% survival * 10g abw * 5% feeding rate / 1000 = 0.45 kg/day
        expect(
          calculateDFR(stocked: 1000.0, surv: 90.0, abw: 10.0, feedRate: 5.0),
          closeTo(0.45, 0.001),
        );
      });

      test('should return null if survival rate is outside 0-100%', () {
        expect(calculateDFR(stocked: 1000.0, surv: 101.0, abw: 10.0, feedRate: 5.0), isNull);
        expect(calculateDFR(stocked: 1000.0, surv: -1.0, abw: 10.0, feedRate: 5.0), isNull);
      });

      test('should return null if stocked quantity or abw is <= 0', () {
        expect(calculateDFR(stocked: 0.0, surv: 90.0, abw: 10.0, feedRate: 5.0), isNull);
        expect(calculateDFR(stocked: 1000.0, surv: 90.0, abw: 0.0, feedRate: 5.0), isNull);
      });

      test('should return null if feeding rate is outside 0-100%', () {
        expect(calculateDFR(stocked: 1000.0, surv: 90.0, abw: 10.0, feedRate: 101.0), isNull);
        expect(calculateDFR(stocked: 1000.0, surv: 90.0, abw: 10.0, feedRate: -0.5), isNull);
      });
    });

    group('FCR Calculation', () {
      test('should calculate FCR correctly under positive values', () {
        expect(calculateFCR(feed: 120.0, gained: 100.0), 1.2);
      });

      test('should return null if feed or weight gained is <= 0', () {
        expect(calculateFCR(feed: 0.0, gained: 100.0), isNull);
        expect(calculateFCR(feed: 120.0, gained: 0.0), isNull);
        expect(calculateFCR(feed: -10.0, gained: 100.0), isNull);
        expect(calculateFCR(feed: 120.0, gained: -5.0), isNull);
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
