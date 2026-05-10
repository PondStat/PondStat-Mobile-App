import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/config/env_config.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';

void main() {
  group('Firebase Providers', () {
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
