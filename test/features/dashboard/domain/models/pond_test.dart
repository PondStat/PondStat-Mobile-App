import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';

void main() {
  group('Pond', () {
    test('fromJson correctly parses all fields', () {
      final Map<String, dynamic> json = {
        'name': 'Pond 1',
        'species': 'Shrimp',
        'stockingQuantity': 1000,
        'targetCulturePeriodDays': 100,
        'ownerId': 'user1',
        'memberIds': ['user1', 'user2'],
        'roles': {'user1': 'owner', 'user2': 'viewer'},
      };
      
      final pond = Pond.fromJson(json, 'p1');
      
      expect(pond.id, 'p1');
      expect(pond.name, 'Pond 1');
      expect(pond.species, 'Shrimp');
      expect(pond.stockingQuantity, 1000);
      expect(pond.targetCulturePeriodDays, 100);
      expect(pond.ownerId, 'user1');
      expect(pond.memberIds, ['user1', 'user2']);
      expect(pond.roles, {'user1': 'owner', 'user2': 'viewer'});
    });

    test('fromJson handles missing optional keys with defaults', () {
      final Map<String, dynamic> json = {};
      
      final pond = Pond.fromJson(json, 'p2');
      
      expect(pond.id, 'p2');
      expect(pond.name, '');
      expect(pond.species, '');
      expect(pond.stockingQuantity, 0);
      expect(pond.targetCulturePeriodDays, 0);
      expect(pond.ownerId, '');
      expect(pond.memberIds, []);
      expect(pond.roles, {});
    });

    test('toJson correctly serializes all fields', () {
      final pond = Pond(
        id: 'p1',
        name: 'Pond 1',
        species: 'Shrimp',
        stockingQuantity: 1000,
        targetCulturePeriodDays: 100,
        ownerId: 'user1',
        memberIds: ['user1'],
        roles: {'user1': 'owner'},
      );
      
      final json = pond.toJson();
      
      expect(json['name'], 'Pond 1');
      expect(json['species'], 'Shrimp');
      expect(json['stockingQuantity'], 1000);
      expect(json['targetCulturePeriodDays'], 100);
      expect(json['ownerId'], 'user1');
      expect(json['memberIds'], ['user1']);
      expect(json['roles'], {'user1': 'owner'});
      expect(json.containsKey('id'), isFalse);
    });

    test('copyWith updates specified fields', () {
      final pond = Pond(
        id: 'p1',
        name: 'Pond 1',
        species: 'Shrimp',
        stockingQuantity: 1000,
        targetCulturePeriodDays: 100,
        ownerId: 'user1',
        memberIds: ['user1'],
        roles: {'user1': 'owner'},
      );
      
      final updatedPond = pond.copyWith(
        name: 'Updated Pond',
        stockingQuantity: 2000,
      );
      
      expect(updatedPond.id, 'p1');
      expect(updatedPond.name, 'Updated Pond');
      expect(updatedPond.species, 'Shrimp');
      expect(updatedPond.stockingQuantity, 2000);
      expect(updatedPond.targetCulturePeriodDays, 100);
      expect(updatedPond.ownerId, 'user1');
      expect(updatedPond.memberIds, ['user1']);
      expect(updatedPond.roles, {'user1': 'owner'});
    });

    test('Equatable value equality works', () {
      final pond1 = Pond(
        id: 'p1',
        name: 'Pond 1',
        species: 'Shrimp',
        stockingQuantity: 1000,
        targetCulturePeriodDays: 100,
        ownerId: 'user1',
        memberIds: ['user1'],
        roles: {'user1': 'owner'},
      );
      
      final pond2 = Pond(
        id: 'p1',
        name: 'Pond 1',
        species: 'Shrimp',
        stockingQuantity: 1000,
        targetCulturePeriodDays: 100,
        ownerId: 'user1',
        memberIds: ['user1'],
        roles: {'user1': 'owner'},
      );

      final pond3 = pond1.copyWith(name: 'Pond 2');
      
      expect(pond1, equals(pond2));
      expect(pond1, isNot(equals(pond3)));
    });
  });
}
