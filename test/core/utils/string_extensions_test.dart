import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/utils/string_extensions.dart';

void main() {
  group('StringExtensions', () {
    test('initials handles null', () {
      String? name;
      expect(name.initials, '?');
    });

    test('initials handles completely empty string', () {
      expect(''.initials, '?');
    });

    test('initials handles whitespace-only strings (fixes crash)', () {
      // This previously crashed the app due to RangeError
      expect('   '.initials, '?');
      expect('\n\t'.initials, '?');
    });

    test('initials extracts single initial correctly', () {
      expect('John'.initials, 'J');
      expect('   john   '.initials, 'J');
    });

    test('initials extracts two initials correctly', () {
      expect('John Doe'.initials, 'JD');
      expect('   john   doe   '.initials, 'JD');
    });

    test('initials extracts max two initials for long names', () {
      expect('John Jacob Jingleheimer Schmidt'.initials, 'JJ');
    });
  });
}
