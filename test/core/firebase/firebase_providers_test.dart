import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pondstat/core/config/env_config.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  group('Firebase Providers', () {
    test('firebaseFirestoreProvider provides FirebaseFirestore', () {
      final fakeFirestore = FakeFirebaseFirestore();
      
      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      
      addTearDown(container.dispose);
      
      final firestore = container.read(firebaseFirestoreProvider);
      expect(firestore, isA<FirebaseFirestore>());
    });

    test('firebaseAuthProvider provides FirebaseAuth', () {
      final mockAuth = MockFirebaseAuth();
      
      final container = ProviderContainer(
        overrides: [
          firebaseAuthProvider.overrideWithValue(mockAuth),
        ],
      );
      
      addTearDown(container.dispose);
      
      final auth = container.read(firebaseAuthProvider);
      expect(auth, isA<FirebaseAuth>());
    });

    test('appBaseRefProvider constructs the correct path', () {
      final fakeFirestore = FakeFirebaseFirestore();
      
      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWithValue(fakeFirestore),
        ],
      );
      
      addTearDown(container.dispose);
      
      final ref = container.read(appBaseRefProvider);
      
      expect(ref.path, 'artifacts/${EnvConfig.appId}/public/data');
    });
  });
}