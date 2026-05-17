import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pondstat/core/config/app_config_provider.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';

void main() {
  group('Firebase Providers', () {
    test('appBaseRefProvider constructs the correct path', () {
      final fakeFirestore = FakeFirebaseFirestore();

      final container = ProviderContainer(
        overrides: [
          firebaseFirestoreProvider.overrideWith((ref) => fakeFirestore)
        ],
      );

      addTearDown(container.dispose);

      final ref = container.read(appBaseRefProvider);
      final config = container.read(appConfigProvider);

      expect(ref.path, 'artifacts/${config.appId}/public/data');
    });
  });
}
