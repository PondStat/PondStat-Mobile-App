// test/features/dashboard/domain/models/pond_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';

void main() {
  test('Pond fromJson and toJson', () {
    final Map<String, dynamic> json = {
      'id': 'p1',
      'name': 'Pond 1',
      'species': 'Shrimp',
      'stockingQuantity': 1000,
      'targetCulturePeriodDays': 100,
      'ownerId': 'user1',
      'memberIds': ['user1'],
      'roles': {'user1': 'owner'},
    };
    
    final pond = Pond.fromJson(json, 'p1');
    expect(pond.name, 'Pond 1');
    expect(pond.toJson()['species'], 'Shrimp');
  });
}
