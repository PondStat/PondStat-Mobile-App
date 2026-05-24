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
      final updatedPond = pond.copyWith(id: newPondRef.id);
      
      // Write atomically in a single set with createdAt serverTimestamp
      final rawRef = _baseRef.collection('ponds').doc(newPondRef.id);
      final json = updatedPond.toJson();
      json['createdAt'] = FieldValue.serverTimestamp();
      await rawRef.set(json);
    });
  }

  Future<void> updatePond(Pond pond) async {
    await runWrite(() => pondsCollection.doc(pond.id).update({
      'name': pond.name,
      'species': pond.species,
      'stockingQuantity': pond.stockingQuantity,
      'targetCulturePeriodDays': pond.targetCulturePeriodDays,
      'updatedAt': FieldValue.serverTimestamp(),
    }));
  }

  Future<void> deletePond(String pondId) async {
    final firestore = _baseRef.firestore;
    final source = isOffline() ? Source.cache : Source.serverAndCache;

    final collectionsToClean = [
      _baseRef.collection('measurements'),
      _baseRef.collection('measurement_history'),
      _baseRef.collection('expenses'),
      _baseRef.collection('pond_expenses'),
      _baseRef.collection('pond_sales'),
      _baseRef.collection('custom_parameters'),
      _baseRef.collection('schedules'),
    ];

    final List<DocumentReference> docsToDelete = [];

    for (final col in collectionsToClean) {
      try {
        final snapshot = await col
            .where('pondId', isEqualTo: pondId)
            .get(GetOptions(source: source));
        for (final doc in snapshot.docs) {
          docsToDelete.add(doc.reference);
        }
      } catch (e) {
        // Silently catch query errors if offline cache has no record of the collection
      }
    }

    // Also delete the pond itself
    docsToDelete.add(pondsCollection.doc(pondId));

    // Delete in chunks of 450 to avoid Firestore's 500-write-batch limit
    const int chunkSize = 450;
    for (int i = 0; i < docsToDelete.length; i += chunkSize) {
      final chunk = docsToDelete.sublist(
        i,
        i + chunkSize > docsToDelete.length ? docsToDelete.length : i + chunkSize,
      );
      final batch = firestore.batch();
      for (final docRef in chunk) {
        batch.delete(docRef);
      }
      await commitBatchWithTimeout(batch);
    }
  }
}
