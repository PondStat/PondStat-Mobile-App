import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pondstat/core/firebase/firestore_helper.dart';

class DashboardRepository {
  static final DashboardRepository _instance = DashboardRepository._internal();
  factory DashboardRepository() => _instance;
  DashboardRepository._internal();

  Stream<QuerySnapshot> getUserPondsStream(String userId) {
    return FirestoreHelper.pondsCollection
        .where('memberIds', arrayContains: userId)
        .snapshots();
  }

  Future<void> createPond({
    required String name,
    required String species,
    required int stockingQuantity,
    required int targetCulturePeriodDays,
    required String userId,
  }) async {
    final newPondRef = FirestoreHelper.pondsCollection.doc();

    await newPondRef.set({
      'name': name,
      'species': species,
      'stockingQuantity': stockingQuantity,
      'targetCulturePeriodDays': targetCulturePeriodDays,
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': userId,
      'memberIds': [userId],
      'roles': {userId: 'owner'},
    });
  }

  Future<void> updatePond({
    required String pondId,
    required String name,
    required String species,
    required int stockingQuantity,
    required int targetCulturePeriodDays,
  }) async {
    final pondRef = FirestoreHelper.pondsCollection.doc(pondId);

    await pondRef.update({
      'name': name,
      'species': species,
      'stockingQuantity': stockingQuantity,
      'targetCulturePeriodDays': targetCulturePeriodDays,
    });
  }

  Future<void> deletePond(String pondId) async {
    await FirestoreHelper.pondsCollection.doc(pondId).delete();
  }
}
