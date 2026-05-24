import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pondstat/core/firebase/firebase_providers.dart';
import 'package:pondstat/features/dashboard/domain/models/pond.dart';
import 'package:pondstat/core/services/connectivity_provider.dart';
import 'package:pondstat/core/firebase/offline_repository_mixin.dart';

part 'pond_repository.g.dart';

@riverpod
PondRepository pondRepository(Ref ref) {
  final baseRef = ref.watch(appBaseRefProvider);
  return PondRepository(
    baseRef,
    isOffline: () => ref.read(isOfflineProvider),
  );
}

class PondRepository with OfflineRepositoryMixin {
  final DocumentReference<Map<String, dynamic>> _baseRef;
  @override
  final bool Function() isOffline;

  PondRepository(
    this._baseRef, {
    required this.isOffline,
  });

  CollectionReference<Pond> get pondsCollection {
    return _baseRef
        .collection('ponds')
        .withConverter<Pond>(
          fromFirestore: (snapshot, _) {
              final data = snapshot.data()!;
              data['id'] = snapshot.id;
              return Pond.fromJson(data);
            },
          toFirestore: (pond, _) => pond.toJson(),
        );
  }

  Stream<List<Pond>> getUserPondsStream(String userId) {
    return pondsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> createPond(Pond pond) async {
    await runWrite(() async {
      final newPondRef = pondsCollection.doc();
      await newPondRef.set(pond);
      await newPondRef.update({'createdAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> updatePond(Pond pond) async {
    await runWrite(() => pondsCollection.doc(pond.id).update({
      'name': pond.name,
      'species': pond.species,
      'stockingQuantity': pond.stockingQuantity,
      'targetCulturePeriodDays': pond.targetCulturePeriodDays,
    }));
  }

  Future<void> deletePond(String pondId) async {
    await runWrite(() => pondsCollection.doc(pondId).delete());
  }
}
