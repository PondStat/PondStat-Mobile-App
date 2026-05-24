import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pondstat/features/monitoring/data/finances_repository.dart';

class MockUser extends Mock implements User {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('FinancesRepository Tests', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late FinancesRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();

      when(() => mockUser.uid).thenReturn('test-user-id');
      when(() => mockUser.displayName).thenReturn('Test User');
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final baseRef = fakeFirestore.doc('artifacts/test-app-id/public/data');
      repository = FinancesRepository(baseRef, mockAuth);
    });

    test('addExpense saves correct data to Firestore', () async {
      await repository.addExpense(
        pondId: 'test-pond-id',
        item: 'Feed',
        quantity: 5,
        amountPerItem: 120.0,
        totalAmount: 600.0,
      );

      final snapshot = await repository.expensesCollection.get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['pondId'], 'test-pond-id');
      expect(data['item'], 'Feed');
      expect(data['quantity'], 5);
      expect(data['amountPerItem'], 120.0);
      expect(data['totalAmount'], 600.0);
      expect(data['buyerId'], 'test-user-id');
      expect(data['buyerName'], 'Test User');
      expect(data['timestamp'], isNotNull);
    });

    test('addPondExpense saves correct data to Firestore', () async {
      await repository.addPondExpense(
        pondId: 'test-pond-id',
        category: 'Labor',
        item: 'Pond Cleaning',
        quantity: 2.0,
        unit: 'days',
        amountPerUnit: 500.0,
        totalAmount: 1000.0,
        notes: 'Cleaning leaves and debris',
      );

      final snapshot = await repository.pondExpensesCollection.get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['pondId'], 'test-pond-id');
      expect(data['category'], 'Labor');
      expect(data['item'], 'Pond Cleaning');
      expect(data['quantity'], 2.0);
      expect(data['unit'], 'days');
      expect(data['amountPerUnit'], 500.0);
      expect(data['totalAmount'], 1000.0);
      expect(data['recordedById'], 'test-user-id');
      expect(data['recordedByName'], 'Test User');
      expect(data['notes'], 'Cleaning leaves and debris');
    });

    test('addPondSale saves correct data to Firestore', () async {
      await repository.addPondSale(
        pondId: 'test-pond-id',
        buyerName: 'Buyer A',
        productName: 'Shrimp',
        quantity: 10.5,
        unit: 'kg',
        pricePerUnit: 350.0,
        totalAmount: 3675.0,
        notes: 'Premium quality harvested shrimp',
      );

      final snapshot = await repository.pondSalesCollection.get();
      expect(snapshot.docs.length, 1);

      final data = snapshot.docs.first.data();
      expect(data['pondId'], 'test-pond-id');
      expect(data['buyerName'], 'Buyer A');
      expect(data['productName'], 'Shrimp');
      expect(data['quantity'], 10.5);
      expect(data['unit'], 'kg');
      expect(data['pricePerUnit'], 350.0);
      expect(data['totalAmount'], 3675.0);
      expect(data['recordedById'], 'test-user-id');
      expect(data['recordedByName'], 'Test User');
      expect(data['notes'], 'Premium quality harvested shrimp');
    });

    test('deleteExpense removes the correct document', () async {
      final docRef = await repository.expensesCollection.add({
        'pondId': 'test-pond-id',
        'item': 'Feed',
        'totalAmount': 500.0,
      });

      var snapshot = await repository.expensesCollection.get();
      expect(snapshot.docs.length, 1);

      await repository.deleteExpense(docRef.id);

      snapshot = await repository.expensesCollection.get();
      expect(snapshot.docs.length, 0);
    });
  });
}
